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

steps=(
  "bash ${SCRIPT_DIR}/check-working-directory-alignment.sh ${repo}"
  "bash ${SCRIPT_DIR}/check-project-target-consistency.sh ${repo}"
  "bash ${SCRIPT_DIR}/check-fleet-readiness.sh ${repo}"
  "bash ${SCRIPT_DIR}/repair-safe-permission-drift.sh ${repo}"
  "bash ${SCRIPT_DIR}/discover-validation-commands.sh ${repo}"
  "bash ${SCRIPT_DIR}/run-validation-autopilot.sh ${repo}"
  "bash ${SCRIPT_DIR}/check-runtime-foundations.sh ${repo}"
  "bash ${SCRIPT_DIR}/check-network-bindings.sh ${repo}"
  "bash ${SCRIPT_DIR}/check-context-freshness.sh ${repo}"
  "bash ${SCRIPT_DIR}/score-quality-gates.sh ${repo}"
  "bash ${SCRIPT_DIR}/emit-status-report.sh ${repo}"
)

failed=0
failed_step=""
for step in "${steps[@]}"; do
  out_file="$(mktemp)"
  err_file="$(mktemp)"
  if ! bash -lc "$step" >"${out_file}" 2>"${err_file}"; then
    failed=1
    failed_step="$step"
    rm -f "${out_file}" "${err_file}"
    break
  fi
  rm -f "${out_file}" "${err_file}"
done

if [[ "$json_mode" -eq 1 ]]; then
  if [[ "$failed" -eq 0 ]]; then
    aiaast_json_ok '{"status":"pass"}' "run-app-delivery-autopilot.sh" "delivery"
  else
    aiaast_json_error "autopilot_failed" "delivery autopilot failed" "run-app-delivery-autopilot.sh" "delivery" "{\"failed_step\":\"${failed_step}\"}"
  fi
else
  echo "app_delivery_autopilot_$([[ "$failed" -eq 0 ]] && echo ok || echo fail)"
fi
exit "$failed"
