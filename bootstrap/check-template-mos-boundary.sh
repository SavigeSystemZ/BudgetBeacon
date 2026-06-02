#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"
if [[ $# -lt 1 ]]; then
  echo "usage: $0 <target-repo>"
  exit 2
fi
repo="$1"
json_mode=0
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json_mode=1; shift ;;
    *)
      if [[ "$json_mode" -eq 1 ]]; then
        aiaast_json_error "invalid_argument" "unknown arg: $1" "check-template-mos-boundary.sh" "validation"
      else
        echo "unknown arg: $1"
      fi
      exit 2
      ;;
  esac
done
if [[ "$repo" == *"/TEMPLATE" ]]; then
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_ok '{"status":"pass","context":"template-root"}' "check-template-mos-boundary.sh" "validation"
  else
    echo "template/mos boundary check: PASS (template root)"
  fi
  exit 0
fi
for banned in "MOS_TEMPLATE/" "_MOS_TEMPLATE_FACTORY/" "MOS_SOURCE_LIBRARY/"; do
  if [[ -e "${repo}/${banned}" ]]; then
    if [[ "$json_mode" -eq 1 ]]; then
      aiaast_json_error "boundary_violation" "boundary violation: found ${banned}" "check-template-mos-boundary.sh" "validation"
    else
      echo "boundary violation: found ${banned}"
    fi
    exit 1
  fi
done
if [[ "$json_mode" -eq 1 ]]; then
  aiaast_json_ok '{"status":"pass","context":"downstream"}' "check-template-mos-boundary.sh" "validation"
else
  echo "template/mos boundary check: PASS"
fi

