#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"
if [[ $# -lt 1 ]]; then
  echo "usage: $0 <target-repo> [--json]"
  exit 2
fi
repo="$1"; shift || true
json_mode=0
[[ "${1:-}" == "--json" ]] && json_mode=1

out_file="$(mktemp)"
err_file="$(mktemp)"
if bash "${SCRIPT_DIR}/check-agent-locks.sh" "$repo" --strict >"${out_file}" 2>"${err_file}"; then
  rm -f "${out_file}" "${err_file}"
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_ok '{"status":"ready"}' "check-fleet-readiness.sh" "fleet"
  else
    echo "fleet_readiness: READY"
  fi
  exit 0
fi
rm -f "${out_file}" "${err_file}"

if [[ "$json_mode" -eq 1 ]]; then
  aiaast_json_error "fleet_not_ready" "fleet readiness check failed" "check-fleet-readiness.sh" "fleet"
else
  echo "fleet_readiness: NOT_READY"
fi
exit 1
