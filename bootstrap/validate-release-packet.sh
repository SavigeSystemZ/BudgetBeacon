#!/usr/bin/env bash
# validate-release-packet.sh
#
# Validates a release packet payload + its artifact index against canonical
# schemas, and verifies the packet's checksum manifest. If no path is given,
# validates the most recent retained packet under
# <repo>/_META_AGENT_SYSTEM/evidence/release-packets/.
#
# Pure read; never re-builds a packet.
#
# Usage:
#   validate-release-packet.sh <repo-root> [--packet <path>] [--latest] [--skip-checksums] [--json]
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <repo-root> [--packet <path>] [--latest] [--skip-checksums] [--json]"
  exit 2
fi

repo="$1"; shift || true
packet=""
latest=0
json_mode=0
skip_checksums=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --packet) packet="$2"; shift 2 ;;
    --latest) latest=1; shift ;;
    --skip-checksums) skip_checksums=1; shift ;;
    --json) json_mode=1; shift ;;
    *)
      [[ "$json_mode" -eq 1 ]] && aiaast_json_error "invalid_argument" "unknown arg: $1" "validate-release-packet.sh" "schema"
      [[ "$json_mode" -eq 0 ]] && echo "unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

schema_packet="${repo}/_system/schemas/release-packet.schema.json"
schema_artifacts="${repo}/_system/schemas/release-packet-artifacts.schema.json"
for cand in "${schema_packet}" "${schema_artifacts}"; do
  if [[ ! -f "${cand}" ]]; then
    alt="${SCRIPT_DIR}/../_system/schemas/$(basename "${cand}")"
    [[ -f "${alt}" ]] && {
      [[ "${cand}" == "${schema_packet}" ]] && schema_packet="${alt}" || schema_artifacts="${alt}"
    }
  fi
done

if [[ -z "${packet}" || "${latest}" -eq 1 ]]; then
  packets_dir="${repo}/_META_AGENT_SYSTEM/evidence/release-packets"
  if [[ ! -d "${packets_dir}" ]]; then
    [[ "$json_mode" -eq 1 ]] && aiaast_json_error "missing_packets_dir" "${packets_dir}" "validate-release-packet.sh" "schema"
    [[ "$json_mode" -eq 0 ]] && echo "missing packets dir: ${packets_dir}" >&2
    exit 1
  fi
  packet="$(ls -1 "${packets_dir}"/RELEASE_PACKET_*.json 2>/dev/null | grep -v '\.artifacts\.json$' | sort | tail -n1 || true)"
fi

if [[ -z "${packet}" || ! -f "${packet}" ]]; then
  [[ "$json_mode" -eq 1 ]] && aiaast_json_error "missing_packet" "no release packet json found" "validate-release-packet.sh" "schema"
  [[ "$json_mode" -eq 0 ]] && echo "no release packet json found" >&2
  exit 1
fi

for s in "${schema_packet}" "${schema_artifacts}"; do
  if [[ ! -f "${s}" ]]; then
    [[ "$json_mode" -eq 1 ]] && aiaast_json_error "missing_schema" "${s}" "validate-release-packet.sh" "schema"
    [[ "$json_mode" -eq 0 ]] && echo "missing schema: ${s}" >&2
    exit 1
  fi
done

py_out_file="$(mktemp)"
trap 'rm -f "${py_out_file}"' EXIT

if ! python3 - "${packet}" "${schema_packet}" "${schema_artifacts}" "${skip_checksums}" >"${py_out_file}" <<'PY'
from __future__ import annotations
import hashlib, json, os, re, subprocess, sys

packet_path, schema_packet, schema_artifacts, skip_csum = sys.argv[1:]
skip_csum = skip_csum == "1"

with open(packet_path, "r", encoding="utf-8") as fh:
    packet = json.load(fh)
with open(schema_packet, "r", encoding="utf-8") as fh:
    sch_p = json.load(fh)
with open(schema_artifacts, "r", encoding="utf-8") as fh:
    sch_a = json.load(fh)

errors = []
def err(msg, where="$"):
    errors.append({"path": where, "message": msg})

def check(node, sch, where="$"):
    t = sch.get("type")
    if t == "object":
        if not isinstance(node, dict):
            err(f"expected object, got {type(node).__name__}", where); return
        for k in sch.get("required", []):
            if k not in node:
                err(f"missing required key '{k}'", where)
        props = sch.get("properties", {})
        for k, v in node.items():
            if k in props:
                check(v, props[k], f"{where}.{k}")
    elif t == "array":
        if not isinstance(node, list):
            err(f"expected array, got {type(node).__name__}", where); return
        items = sch.get("items")
        if items:
            for i, el in enumerate(node):
                check(el, items, f"{where}[{i}]")
        if "minItems" in sch and len(node) < sch["minItems"]:
            err(f"minItems {sch['minItems']} violated (got {len(node)})", where)
    elif t == "string":
        if not isinstance(node, str):
            err(f"expected string, got {type(node).__name__}", where); return
        if "pattern" in sch and not re.search(sch["pattern"], node):
            err(f"pattern mismatch /{sch['pattern']}/", where)
        if "enum" in sch and node not in sch["enum"]:
            err(f"value '{node}' not in enum {sch['enum']}", where)
        if "minLength" in sch and len(node) < sch["minLength"]:
            err(f"minLength {sch['minLength']} violated", where)
    elif t == "integer":
        if not isinstance(node, int) or isinstance(node, bool):
            err(f"expected integer, got {type(node).__name__}", where); return
        if "minimum" in sch and node < sch["minimum"]:
            err(f"min {sch['minimum']} violated", where)

check(packet, sch_p, "$packet")

# Validate artifact index
ai_path = packet.get("artifact_index")
ai_doc = None
if ai_path and os.path.isfile(ai_path):
    with open(ai_path, "r", encoding="utf-8") as fh:
        ai_doc = json.load(fh)
    check(ai_doc, sch_a, "$artifacts")
    declared = packet.get("artifact_count")
    if isinstance(ai_doc, dict):
        actual = ai_doc.get("artifact_count")
        if declared != actual:
            err(f"packet artifact_count={declared} != index artifact_count={actual}")
        items = ai_doc.get("artifacts", []) or []
        if isinstance(items, list) and len(items) != actual:
            err(f"index artifact_count={actual} != items length={len(items)}")
        # determinism: must be sorted by path
        paths = [a.get("path") for a in items if isinstance(a, dict)]
        if paths != sorted(paths):
            err("artifact list is not sorted lexicographically by path")
    # artifact_index_sha256 sanity
    with open(ai_path, "rb") as fh:
        ai_sha = hashlib.sha256(fh.read()).hexdigest()
    if packet.get("artifact_index_sha256") != ai_sha:
        err(f"artifact_index_sha256 mismatch: declared={packet.get('artifact_index_sha256')} actual={ai_sha}")
    sig = packet.get("signature", {}) or {}
    if sig.get("artifact_index_sha256") != ai_sha:
        err(f"signature.artifact_index_sha256 mismatch with file sha")
else:
    err(f"artifact_index file not found at {ai_path}")

# Verify checksums file if present
csum_path = packet.get("checksums")
checksum_check = "skipped"
if csum_path and not skip_csum and os.path.isfile(csum_path):
    try:
        # Checksum file paths are relative to source_root.
        cwd = packet.get("source_root") or os.path.dirname(csum_path)
        rc = subprocess.run(["sha256sum", "-c", csum_path],
                            cwd=cwd, capture_output=True, text=True)
        if rc.returncode != 0:
            err(f"sha256sum -c failed: {rc.stdout.strip()} {rc.stderr.strip()}")
            checksum_check = "fail"
        else:
            checksum_check = "pass"
    except Exception as e:
        err(f"checksum verification error: {e}")
        checksum_check = "error"
elif csum_path and skip_csum:
    checksum_check = "skipped"
else:
    err(f"checksums file not found at {csum_path}")

print(json.dumps({
    "ok": len(errors) == 0,
    "packet": packet_path,
    "artifact_index": ai_path,
    "checksum_check": checksum_check,
    "error_count": len(errors),
    "errors": errors[:50],
    "version": packet.get("version"),
    "artifact_count": packet.get("artifact_count"),
}))
PY
then
  rc=$?
  [[ "$json_mode" -eq 1 ]] && aiaast_json_error "validator_failed" "rc=${rc}" "validate-release-packet.sh" "schema"
  cat "${py_out_file}" >&2
  exit "${rc}"
fi

result="$(cat "${py_out_file}")"
ok="$(printf '%s' "${result}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["ok"])')"

if [[ "${ok}" == "True" ]]; then
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_ok "${result}" "validate-release-packet.sh" "schema"
  else
    echo "release_packet_schema_ok"
  fi
  exit 0
else
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_error "schema_violations" "release packet validation failed" "validate-release-packet.sh" "schema" "${result}"
  else
    echo "release_packet_schema_fail"
    echo "${result}"
  fi
  exit 1
fi
