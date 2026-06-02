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

run_check() {
  local name="$1"; shift
  local out_file err_file
  out_file="$(mktemp)"
  err_file="$(mktemp)"
  if "$@" >"${out_file}" 2>"${err_file}"; then
    rm -f "${out_file}" "${err_file}"
    echo "{\"name\":\"${name}\",\"status\":\"pass\"}"
  else
    rm -f "${out_file}" "${err_file}"
    echo "{\"name\":\"${name}\",\"status\":\"fail\"}"
    return 1
  fi
}

failed=0
results="["
for cmd in \
  "aiast-cli check-awareness" \
  "validate-system.sh --strict"
do
  script_name="${cmd%% *}"
  if [[ -x "${repo}/bootstrap/${script_name}" ]]; then
    # shellcheck disable=SC2206
    args=( $cmd )
    out="$(run_check "$cmd" "${repo}/bootstrap/${args[0]}" "${repo}" "${args[@]:1}")" || failed=1
    [[ "$results" != "[" ]] && results+=","
    results+="$out"
  fi
done
results+="]"

if [[ "$json_mode" -eq 1 ]]; then
  if [[ "$failed" -eq 0 ]]; then
    aiaast_json_ok "{\"checks\":${results}}" "run-validation-autopilot.sh" "validation"
  else
    aiaast_json_error "validation_failed" "one or more validations failed" "run-validation-autopilot.sh" "validation" "{\"checks\":${results}}"
  fi
else
  echo "validation_autopilot_results=${results}"
fi

exit "$failed"
