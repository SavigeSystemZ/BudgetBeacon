#!/usr/bin/env bash
# Sync both hybrid repos (`app-runtime` and `app-meta`) under APP_ROOT without
# running per-repo `validate-system.sh` (those trees are shards; gates run from
# the umbrella directory or CI). Uses `_system/gitops-policy.json` for base
# branch and private-remote checks when present.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
usage: hybrid-git-sync.sh [--app-root PATH]

Fetch, prune, and rebase both `APP_ROOT/app-runtime` and `APP_ROOT/app-meta`
onto origin/<base> (default policy: main).

Environment:
  APP_ROOT                     App umbrella path (Hybrid layout root).
EOF
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

policy_file() {
  local c1="$1/_system/gitops-policy.json"
  local c2="$1/app-meta/_system/gitops-policy.json"
  if [[ -f "${c1}" ]]; then
    echo "${c1}"
    return
  fi
  if [[ -f "${c2}" ]]; then
    echo "${c2}"
    return
  fi
  echo ""
}

policy_base_branch() {
  local root="$1" pf
  pf="$(policy_file "${root}")"
  if [[ -z "${pf}" ]]; then
    echo "main"
    return
  fi
  python3 -c 'import json,sys; print(json.load(open(sys.argv[1],encoding="utf-8")).get("default_base_branch","main"))' "${pf}"
}

policy_require_private_remote() {
  local root="$1" pf
  pf="$(policy_file "${root}")"
  if [[ -z "${pf}" ]]; then
    echo "false"
    return
  fi
  python3 -c 'import json,sys; v=json.load(open(sys.argv[1],encoding="utf-8")).get("require_private_remotes", False); print("true" if v else "false")' "${pf}"
}

validate_private_origin() {
  local repo_path="$1"
  local remote_url
  remote_url="$(git -C "${repo_path}" remote get-url origin 2>/dev/null || true)"
  if [[ -z "${remote_url}" ]]; then
    echo "hybrid-git-sync: ${repo_path}: no origin remote" >&2
    return 1
  fi
  local req
  req="$(policy_require_private_remote "${APP_ROOT}")"
  if [[ "${req}" == "true" ]] && [[ "${remote_url}" == https://github.com/* ]]; then
    echo "hybrid-git-sync: ${repo_path}: policy requires non-HTTPS origin for private remotes (${remote_url})" >&2
    return 1
  fi
  return 0
}

sync_one() {
  local repo_path="$1" base="$2"
  validate_private_origin "${repo_path}" || return 1
  git -C "${repo_path}" fetch --all --prune
  if git -C "${repo_path}" show-ref --verify --quiet "refs/remotes/origin/${base}"; then
    git -C "${repo_path}" rebase "origin/${base}"
  fi
}

log_event() {
  local status="$1" cmd="$2" details="${3:-{}}"
  mkdir -p "${APP_ROOT}/ops/logs"
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
    "tool": "hybrid-git-sync",
    "command": cmd,
    "status": status,
    "app_root": app_root,
    "details": details,
}
with open(out, "a", encoding="utf-8") as f:
    f.write(json.dumps(event, sort_keys=True) + "\n")
PY
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --app-root) APP_ROOT="$2"; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      *) echo "hybrid-git-sync: unknown option: $1" >&2; usage; exit 2 ;;
    esac
  done

  APP_ROOT="$(app_root_from_env_or_pwd)"
  APP_ROOT="$(cd -- "${APP_ROOT}" && pwd)"

  local rt="${APP_ROOT}/app-runtime"
  local mt="${APP_ROOT}/app-meta"

  git -C "${rt}" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "hybrid-git-sync: not a git repository: ${rt}" >&2
    exit 1
  }
  git -C "${mt}" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "hybrid-git-sync: not a git repository: ${mt}" >&2
    exit 1
  }

  local base
  base="$(policy_base_branch "${APP_ROOT}")"

  sync_one "${rt}" "${base}"
  sync_one "${mt}" "${base}"

  log_event "ok" "sync-both" "{\"base\":\"${base}\",\"repos\":[\"app-runtime\",\"app-meta\"]}"
  echo "hybrid_git_sync_ok base=${base} app-runtime app-meta"
}

main "$@"
