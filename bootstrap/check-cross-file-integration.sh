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
        aiaast_json_error "invalid_argument" "unknown arg: $1" "check-cross-file-integration.sh" "validation"
      else
        echo "unknown arg: $1"
      fi
      exit 2
      ;;
  esac
done
req=(
  "_system/SUPER_TEMPLATE_MASTER_MAP.md"
  "_system/CONCURRENT_AGENT_FLEET_PROTOCOL.md"
  "_system/CONTINUOUS_CONTEXT_RECORDING_PROTOCOL.md"
  "_system/SCAFFOLD_PROFILE_MATRIX.md"
  "_system/APP_ARCHETYPE_ROUTING_MATRIX.md"
  "_system/TOOL_MEMORY_REDIRECTION_PROTOCOL.md"
  "_system/TEMPLATE_MOS_AND_BUILDER_APP_BOUNDARY.md"
)
for p in "${req[@]}"; do
  [[ -f "${repo}/${p}" ]] || {
    if [[ "$json_mode" -eq 1 ]]; then
      aiaast_json_error "missing_file" "missing integration file: ${p}" "check-cross-file-integration.sh" "validation"
    else
      echo "missing integration file: ${p}"
    fi
    exit 1
  }
done
if [[ "$json_mode" -eq 1 ]]; then
  aiaast_json_ok '{"status":"pass"}' "check-cross-file-integration.sh" "validation"
else
  echo "cross-file integration check: PASS"
fi

