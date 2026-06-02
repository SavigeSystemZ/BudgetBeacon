#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <template-root> [--root PATH] [--execute] [--apply] [--profiles CSV] [--archetypes CSV] [--mode fast|strict|both] [--limit-cells N] [--json]"
  exit 2
fi

repo="$1"
shift || true
args=()
json_mode=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root|--profiles|--archetypes|--mode|--limit-cells)
      args+=("$1" "${2:-}")
      shift 2
      ;;
    --execute|--apply)
      args+=("$1")
      shift
      ;;
    --json)
      json_mode=1
      args+=("$1")
      shift
      ;;
    *)
      [[ "${json_mode}" -eq 1 ]] && aiaast_json_error "invalid_argument" "unknown arg: $1" "run-test-app-campaign.sh" "campaign"
      [[ "${json_mode}" -eq 0 ]] && echo "unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

exec bash "${SCRIPT_DIR}/run-test-app-benchmark-matrix.sh" "${repo}" "${args[@]}"
