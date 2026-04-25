#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: check-global-shim-alignment.sh [--myappz-root <path>] [--json]
EOF
}

MYAPPZ_ROOT="${HOME}/.MyAppZ"
JSON_OUTPUT=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --myappz-root) MYAPPZ_ROOT="${2:-}"; shift 2 ;;
    --json) JSON_OUTPUT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unexpected argument: $1" >&2; exit 1 ;;
  esac
done

MYAPPZ_ROOT="$(cd -- "${MYAPPZ_ROOT}" && pwd)"
status="global_shim_alignment_ok"
issues=()
shim="${MYAPPZ_ROOT}/AGENTS.md"

if [[ -f "${shim}" ]]; then
  text="$(python3 - <<'PY' "${shim}"
import sys
print(open(sys.argv[1]).read())
PY
)"
  if [[ "${text}" != *"Redirect Shim"* ]]; then
    issues+=("root_shim_missing_redirect_header")
  fi
  if [[ "${text}" == *"_system/INSTRUCTION_PRECEDENCE_CONTRACT.md"* ]]; then
    issues+=("root_shim_contains_large_authoritative_body")
  fi
fi

if [[ ${#issues[@]} -gt 0 ]]; then
  status="global_shim_alignment_fail"
fi

if [[ ${JSON_OUTPUT} -eq 1 ]]; then
  python3 - <<'PY' "${status}" "$(IFS=,; echo "${issues[*]:-none}")" "${shim}"
import json, sys
print(json.dumps({
  "status": sys.argv[1],
  "issues": [] if sys.argv[2] == "none" else sys.argv[2].split(","),
  "root_shim": sys.argv[3]
}, indent=2))
PY
else
  echo "${status}"
  if [[ ${#issues[@]} -gt 0 ]]; then
    printf 'issues=%s\n' "$(IFS=,; echo "${issues[*]}")"
  fi
fi

[[ "${status}" != "global_shim_alignment_fail" ]]
