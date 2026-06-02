#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <target-repo-or-template> [--json]"
  exit 2
fi

ROOT="$1"
shift || true
JSON_MODE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_MODE=1; shift ;;
    *)
      [[ "${JSON_MODE}" -eq 1 ]] && aiaast_json_error "invalid_argument" "unknown arg: $1" "check-installer-first-gate.sh" "validation"
      [[ "${JSON_MODE}" -eq 0 ]] && echo "unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

ROOT="$(cd -- "${ROOT}" && pwd)"
template_dir="${ROOT}/bootstrap/templates/runtime/ops/install"
runtime_dir="${ROOT}/ops/install"

required=(
  install.sh
  repair.sh
  uninstall.sh
  purge.sh
  status.sh
  doctor.sh
  logs.sh
  open.sh
  start.sh
  stop.sh
  restart.sh
)

missing=()
for rel in "${required[@]}"; do
  if [[ -f "${runtime_dir}/${rel}" || -f "${template_dir}/${rel}" ]]; then
    continue
  fi
  missing+=("${rel}")
done

if [[ "${#missing[@]}" -gt 0 ]]; then
  if [[ "${JSON_MODE}" -eq 1 ]]; then
    details="$(printf '%s\n' "${missing[@]}" | python3 -c 'import json,sys; print(json.dumps({"missing": [line.strip() for line in sys.stdin if line.strip()]}))')"
    aiaast_json_error "installer_lifecycle_incomplete" "installer-first lifecycle scripts are missing" "check-installer-first-gate.sh" "validation" "${details}"
  else
    echo "installer-first gate: FAIL" >&2
    printf 'missing lifecycle script: %s\n' "${missing[@]}" >&2
  fi
  exit 1
fi

if [[ "${JSON_MODE}" -eq 1 ]]; then
  aiaast_json_ok "{\"required_count\":${#required[@]}}" "check-installer-first-gate.sh" "validation"
else
  echo "installer-first gate: PASS scripts=${#required[@]}"
fi
