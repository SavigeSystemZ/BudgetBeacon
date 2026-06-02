#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
usage: snapshotctl.sh <command> [options]

Commands:
  create [--class checkpoint|milestone|release] [--app-root PATH]
  verify --id <snapshot_id> [--app-root PATH]
  encrypt --id <snapshot_id> [--recipient AGE_RECIPIENT|--gpg-recipient ID] [--app-root PATH]
  publish --id <snapshot_id> (--remote-dir PATH|--target NAME) [--app-root PATH]
  catalog [--app-root PATH]
  restore-dry-run --id <snapshot_id> [--app-root PATH]
  restore --id <snapshot_id> [--dest PATH] [--app-root PATH]

Publish policy:
  When `_system/snapshot-remote-targets.json` sets policy.allow_unencrypted_publish
  to false (default template), publishing requires a sibling encrypted artifact:
  archives/<id>.tar.zst.age or .gpg produced by encrypt. Plain tar.zst uploads
  are rejected unless policy explicitly allows them.
EOF
}

snapshot_policy_file() {
  local p1="${APP_ROOT}/_system/snapshot-retention-policy.json"
  local p2="${APP_ROOT}/app-meta/_system/snapshot-retention-policy.json"
  if [[ -f "${p1}" ]]; then
    echo "${p1}"
    return
  fi
  if [[ -f "${p2}" ]]; then
    echo "${p2}"
    return
  fi
  echo ""
}

snapshot_class_allowed() {
  local class="$1"
  local pf
  pf="$(snapshot_policy_file)"
  if [[ -z "${pf}" ]]; then
    [[ "${class}" == "checkpoint" || "${class}" == "milestone" || "${class}" == "release" ]]
    return
  fi
  python3 - "${pf}" "${class}" <<'PY'
import json
import sys
path, klass = sys.argv[1:]
data = json.load(open(path, "r", encoding="utf-8"))
classes = set(data.get("classes", {}).keys())
raise SystemExit(0 if klass in classes else 1)
PY
}

snapshot_compression_flags() {
  local pf
  pf="$(snapshot_policy_file)"
  if [[ -z "${pf}" ]]; then
    echo "zstd -19 --long=31 -T0"
    return
  fi
  python3 -c 'import json,sys; path=sys.argv[1]; data=json.load(open(path,encoding="utf-8")); c=data.get("compression",{}); level=int(c.get("level",19)); lw=int(c.get("long_window",31)); print(f"zstd -{level} --long={lw} -T0")' "${pf}"
}

snapshot_decompress_tar_flag() {
  local pf lw
  pf="$(snapshot_policy_file)"
  lw="31"
  if [[ -n "${pf}" ]]; then
    lw="$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1],encoding="utf-8")); print(int(d.get("compression",{}).get("long_window",31)))' "${pf}")"
  fi
  echo "zstd -d --long=${lw}"
}

remote_targets_file() {
  local r1="${APP_ROOT}/_system/snapshot-remote-targets.json"
  local r2="${APP_ROOT}/app-meta/_system/snapshot-remote-targets.json"
  if [[ -f "${r1}" ]]; then
    echo "${r1}"
    return
  fi
  if [[ -f "${r2}" ]]; then
    echo "${r2}"
    return
  fi
  echo ""
}

publish_allow_unencrypted() {
  local rf
  rf="$(remote_targets_file)"
  if [[ -z "${rf}" ]]; then
    echo "true"
    return
  fi
  python3 -c 'import json,sys; d=json.load(open(sys.argv[1],encoding="utf-8")); a=d.get("policy",{}).get("allow_unencrypted_publish", True); print("true" if a else "false")' "${rf}"
}

publish_requires_private_path() {
  local rf
  rf="$(remote_targets_file)"
  if [[ -z "${rf}" ]]; then
    echo "false"
    return
  fi
  python3 -c 'import json,sys; d=json.load(open(sys.argv[1],encoding="utf-8")); r=d.get("policy",{}).get("require_private_remote", False); print("true" if r else "false")' "${rf}"
}

publish_resolve_remote_dir_from_target() {
  local target_name="$1"
  local rf
  rf="$(remote_targets_file)"
  if [[ -z "${rf}" ]]; then
    echo "snapshot-remote-targets.json missing" >&2
    return 1
  fi
  SNAPSHOT_REMOTE_TARGETS="${rf}" TARGET_NAME="${target_name}" HYBRID_APP_ROOT="${APP_ROOT}" python3 <<'PY'
import json
import os
import sys

path = os.environ["SNAPSHOT_REMOTE_TARGETS"]
target_name = os.environ["TARGET_NAME"]
app_root = os.environ["HYBRID_APP_ROOT"]

data = json.load(open(path, "r", encoding="utf-8"))
app_slug = os.path.basename(os.path.abspath(app_root))
for entry in data.get("targets", []):
    if entry.get("name") != target_name:
        continue
    if not entry.get("enabled", False):
        print(f"snapshotctl: target is disabled in policy: {target_name}", file=sys.stderr)
        raise SystemExit(2)
    tmpl = entry.get("path_template", "").replace("<AppName>", app_slug)
    if not tmpl:
        print("snapshotctl: path_template missing for target", file=sys.stderr)
        raise SystemExit(3)
    print(tmpl)
    raise SystemExit(0)
print(f"snapshotctl: unknown snapshot target {target_name!r}", file=sys.stderr)
raise SystemExit(4)
PY
}

ts_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

app_root_from_env_or_pwd() {
  if [[ -n "${APP_ROOT:-}" ]]; then
    echo "${APP_ROOT}"
    return
  fi
  local cwd
  cwd="$(pwd)"
  if [[ "${cwd}" == */app-runtime ]] || [[ "${cwd}" == */app-meta ]]; then
    dirname "${cwd}"
    return
  fi
  echo "${cwd}"
}

ensure_layout() {
  mkdir -p "${APP_ROOT}/snapshots/archives" \
           "${APP_ROOT}/snapshots/manifests" \
           "${APP_ROOT}/snapshots/index" \
           "${APP_ROOT}/snapshots/restore-sandbox" \
           "${APP_ROOT}/ops/logs"
}

git_sha_or_na() {
  local path="$1"
  if [[ -d "${path}/.git" ]]; then
    git -C "${path}" rev-parse --short HEAD 2>/dev/null || echo "nogit"
  else
    echo "nogit"
  fi
}

semver_or_default() {
  local version_file="${APP_ROOT}/app-runtime/VERSION"
  if [[ -f "${version_file}" ]]; then
    tr -d '\n' < "${version_file}"
  else
    echo "0.0.0"
  fi
}

log_event() {
  local status="$1" cmd="$2" details="${3:-{}}"
  python3 - "$status" "$cmd" "$details" "${APP_ROOT}/ops/logs/operations.jsonl" "${APP_ROOT}" <<'PY'
import json
import sys
from datetime import datetime, timezone
status, cmd, details_raw, out, app_root = sys.argv[1:]
try:
    details = json.loads(details_raw)
except json.JSONDecodeError:
    details = {"message": details_raw}
event = {
    "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "tool": "snapshotctl",
    "command": cmd,
    "status": status,
    "app_root": app_root,
    "details": details,
}
with open(out, "a", encoding="utf-8") as f:
    f.write(json.dumps(event, sort_keys=True) + "\n")
PY
}

create_snapshot() {
  local class="$1"
  snapshot_class_allowed "${class}" || {
    echo "invalid snapshot class: ${class}" >&2
    exit 2
  }
  local semver shortsha lane compact_ts snapshot_id archive_path manifest_path
  semver="$(semver_or_default)"
  shortsha="$(git_sha_or_na "${APP_ROOT}/app-runtime")"
  lane="$(git -C "${APP_ROOT}/app-runtime" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached")"
  compact_ts="$(date -u +"%Y%m%dT%H%M%SZ")"
  snapshot_id="${semver}+snap.${compact_ts}-${shortsha}-${lane//\//-}"
  archive_path="${APP_ROOT}/snapshots/archives/${snapshot_id}.tar.zst"
  manifest_path="${APP_ROOT}/snapshots/manifests/${snapshot_id}.json"

  local compression
  compression="$(snapshot_compression_flags)"
  tar -C "${APP_ROOT}" \
    --exclude='./snapshots/archives' \
    --exclude='./snapshots/restore-sandbox' \
    -I "${compression}" \
    -cf "${archive_path}" \
    app-runtime app-meta ops

  local archive_sha
  archive_sha="$(sha256sum "${archive_path}" | awk '{print $1}')"

  python3 - "${manifest_path}" "${snapshot_id}" "${class}" "${archive_path}" "${archive_sha}" "${APP_ROOT}" <<'PY'
import hashlib
import json
import os
import sys
from datetime import datetime, timezone
manifest_path, snapshot_id, klass, archive_path, archive_sha, app_root = sys.argv[1:]

def tree_hash(root: str) -> str:
    if not os.path.isdir(root):
        return "missing"
    h = hashlib.sha256()
    for base, _, files in os.walk(root):
        files.sort()
        for name in files:
            path = os.path.join(base, name)
            rel = os.path.relpath(path, app_root)
            h.update(rel.encode("utf-8"))
            with open(path, "rb") as f:
                h.update(f.read())
    return h.hexdigest()

runtime_git = "nogit"
meta_git = "nogit"
for role in ("app-runtime", "app-meta"):
    git_dir = os.path.join(app_root, role, ".git")
    if os.path.isdir(git_dir):
        import subprocess
        try:
            sha = subprocess.check_output(
                ["git", "-C", os.path.join(app_root, role), "rev-parse", "HEAD"],
                text=True,
            ).strip()
        except Exception:
            sha = "nogit"
        if role == "app-runtime":
            runtime_git = sha
        else:
            meta_git = sha

manifest = {
    "snapshot_id": snapshot_id,
    "class": klass,
    "created_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "app_name": os.path.basename(app_root.rstrip("/")),
    "operator": os.environ.get("USER", "unknown"),
    "lane": snapshot_id.split("-")[-1],
    "runtime_git_sha": runtime_git,
    "meta_git_sha": meta_git,
    "archive_relpath": os.path.relpath(archive_path, app_root),
    "archive_sha256": archive_sha,
    "file_count": 3,
    "tree_hashes": {
        "app-runtime": tree_hash(os.path.join(app_root, "app-runtime")),
        "app-meta": tree_hash(os.path.join(app_root, "app-meta")),
    },
    "restore_hint": "snapshotctl.sh restore --id " + snapshot_id,
}
with open(manifest_path, "w", encoding="utf-8") as f:
    json.dump(manifest, f, indent=2, sort_keys=True)
    f.write("\n")
PY

  printf '%s\n' "${snapshot_id}" >> "${APP_ROOT}/snapshots/index/snapshot-index.txt"
  log_event "ok" "create" "{\"snapshot_id\":\"${snapshot_id}\",\"class\":\"${class}\"}"
  echo "snapshot_created id=${snapshot_id} archive=${archive_path} manifest=${manifest_path}"
}

manifest_for_id() {
  local id="$1"
  echo "${APP_ROOT}/snapshots/manifests/${id}.json"
}

archive_for_id() {
  local id="$1"
  echo "${APP_ROOT}/snapshots/archives/${id}.tar.zst"
}

verify_snapshot() {
  local id="$1"
  local manifest archive expected got
  manifest="$(manifest_for_id "${id}")"
  archive="$(archive_for_id "${id}")"
  [[ -f "${manifest}" ]] || { echo "missing manifest: ${manifest}" >&2; exit 1; }
  [[ -f "${archive}" ]] || { echo "missing archive: ${archive}" >&2; exit 1; }
  expected="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["archive_sha256"])' "${manifest}")"
  got="$(sha256sum "${archive}" | awk '{print $1}')"
  [[ "${expected}" == "${got}" ]] || { echo "checksum mismatch" >&2; exit 1; }
  log_event "ok" "verify" "{\"snapshot_id\":\"${id}\"}"
  echo "snapshot_verify_ok id=${id}"
}

encrypt_snapshot() {
  local id="$1" mode="$2" recipient="$3"
  local archive out
  archive="$(archive_for_id "${id}")"
  [[ -f "${archive}" ]] || { echo "missing archive: ${archive}" >&2; exit 1; }
  case "${mode}" in
    age)
      out="${archive}.age"
      age -r "${recipient}" -o "${out}" "${archive}"
      ;;
    gpg)
      out="${archive}.gpg"
      gpg --batch --yes --output "${out}" --encrypt --recipient "${recipient}" "${archive}"
      ;;
    *)
      echo "invalid encryption mode" >&2
      exit 2
      ;;
  esac
  log_event "ok" "encrypt" "{\"snapshot_id\":\"${id}\",\"output\":\"${out}\"}"
  echo "snapshot_encrypt_ok id=${id} output=${out}"
}

publish_snapshot() {
  local id="$1" remote_dir="$2"
  local archive manifest
  archive="$(archive_for_id "${id}")"
  manifest="$(manifest_for_id "${id}")"
  [[ -f "${manifest}" ]] || {
    echo "missing manifest: ${manifest}" >&2
    exit 1
  }

  local req_private allow_plain artifact_kind payload
  req_private="$(publish_requires_private_path)"
  allow_plain="$(publish_allow_unencrypted)"
  artifact_kind="plain"
  payload="${archive}"

  if [[ "${req_private}" == "true" ]]; then
    case "${remote_dir}" in
      http://*|https://*)
        echo "snapshotctl: publish path must not use public http(s); use private storage or mounts" >&2
        exit 1
        ;;
    esac
  fi

  if [[ "${allow_plain}" != "true" ]]; then
    if [[ -f "${archive}.age" ]]; then
      payload="${archive}.age"
      artifact_kind="age"
    elif [[ -f "${archive}.gpg" ]]; then
      payload="${archive}.gpg"
      artifact_kind="gpg"
    else
      echo "snapshotctl: policy disallows publishing unencrypted archives; encrypt first:" >&2
      echo "  $0 encrypt --id ${id} --recipient <age_pubkey> | --gpg-recipient <keyid>" >&2
      exit 1
    fi
  fi

  [[ -f "${payload}" ]] || {
    echo "missing payload: ${payload}" >&2
    exit 1
  }

  mkdir -p "${remote_dir}/archives" "${remote_dir}/manifests"
  cp -f "${payload}" "${remote_dir}/archives/"
  cp -f "${manifest}" "${remote_dir}/manifests/"
  log_event "ok" "publish" "{\"snapshot_id\":\"${id}\",\"remote_dir\":\"${remote_dir}\",\"artifact\":\"${artifact_kind}\"}"
  echo "snapshot_publish_ok id=${id} remote=${remote_dir} artifact=${artifact_kind}"
}

catalog_snapshots() {
  ls -1 "${APP_ROOT}/snapshots/manifests"/*.json 2>/dev/null || true
  log_event "ok" "catalog" "{}"
}

restore_dry_run() {
  local id="$1"
  verify_snapshot "${id}"
  tar -tf "$(archive_for_id "${id}")" >/dev/null
  log_event "ok" "restore-dry-run" "{\"snapshot_id\":\"${id}\"}"
  echo "snapshot_restore_dry_run_ok id=${id}"
}

restore_snapshot() {
  # S22a WS7: split declaration — never reference a var being set in the same
  # `local` statement (fragile under `set -u`; the documented WS2 footgun).
  local id="$1"
  local dest="${2:-${APP_ROOT}/snapshots/restore-sandbox/${id}}"
  verify_snapshot "${id}"
  mkdir -p "${dest}"
  local decompress
  decompress="$(snapshot_decompress_tar_flag)"
  tar -C "${dest}" -I "${decompress}" -xf "$(archive_for_id "${id}")"
  log_event "warn" "restore" "{\"snapshot_id\":\"${id}\",\"dest\":\"${dest}\"}"
  echo "snapshot_restore_ok id=${id} dest=${dest}"
}

main() {
  local cmd="${1:-}"
  [[ -n "${cmd}" ]] || { usage; exit 2; }
  shift || true

  APP_ROOT="$(app_root_from_env_or_pwd)"
  ensure_layout

  case "${cmd}" in
    create)
      local class="checkpoint"
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --class) class="$2"; shift 2 ;;
          --app-root) APP_ROOT="$2"; shift 2 ;;
          *) echo "unknown arg: $1" >&2; exit 2 ;;
        esac
      done
      create_snapshot "${class}"
      ;;
    verify)
      [[ "${1:-}" == "--id" ]] || exit 2
      verify_snapshot "${2:-}"
      ;;
    encrypt)
      local id="" mode="" recipient=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --id) id="$2"; shift 2 ;;
          --recipient) mode="age"; recipient="$2"; shift 2 ;;
          --gpg-recipient) mode="gpg"; recipient="$2"; shift 2 ;;
          --app-root) APP_ROOT="$2"; shift 2 ;;
          *) echo "unknown arg: $1" >&2; exit 2 ;;
        esac
      done
      [[ -n "${id}" && -n "${mode}" && -n "${recipient}" ]] || exit 2
      encrypt_snapshot "${id}" "${mode}" "${recipient}"
      ;;
    publish)
      local id="" remote_dir="" target=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --id) id="$2"; shift 2 ;;
          --remote-dir) remote_dir="$2"; shift 2 ;;
          --target) target="$2"; shift 2 ;;
          --app-root) APP_ROOT="$2"; shift 2 ;;
          *) echo "unknown arg: $1" >&2; exit 2 ;;
        esac
      done
      [[ -n "${id}" ]] || exit 2
      if [[ -n "${target}" ]]; then
        remote_dir="$(publish_resolve_remote_dir_from_target "${target}")" || exit 1
      fi
      [[ -n "${remote_dir}" ]] || {
        echo "snapshotctl: provide --remote-dir or --target" >&2
        exit 2
      }
      publish_snapshot "${id}" "${remote_dir}"
      ;;
    catalog)
      catalog_snapshots
      ;;
    restore-dry-run)
      [[ "${1:-}" == "--id" ]] || exit 2
      restore_dry_run "${2:-}"
      ;;
    restore)
      local id="" dest=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --id) id="$2"; shift 2 ;;
          --dest) dest="$2"; shift 2 ;;
          --app-root) APP_ROOT="$2"; shift 2 ;;
          *) echo "unknown arg: $1" >&2; exit 2 ;;
        esac
      done
      [[ -n "${id}" ]] || exit 2
      restore_snapshot "${id}" "${dest}"
      ;;
    *)
      usage
      exit 2
      ;;
  esac
}

main "$@"
