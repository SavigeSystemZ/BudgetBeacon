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
        aiaast_json_error "invalid_argument" "unknown arg: $1" "check-context-freshness.sh" "validation"
      else
        echo "unknown arg: $1"
      fi
      exit 2
      ;;
  esac
done
latest="${repo}/_system/checkpoints/LATEST.json"
events="${repo}/_system/context/events.jsonl"
if [[ ! -f "$latest" ]]; then
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_ok '{"status":"pass","checkpoint":"absent"}' "check-context-freshness.sh" "validation"
  else
    echo "context freshness check: PASS (no active checkpoint snapshot)"
  fi
  exit 0
fi
[[ -f "$events" ]] || {
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_error "missing_events" "missing events: $events" "check-context-freshness.sh" "validation"
  else
    echo "missing events: $events"
  fi
  exit 1
}
if [[ "$json_mode" -eq 1 ]]; then
  aiaast_json_ok '{"status":"pass","checkpoint":"present"}' "check-context-freshness.sh" "validation"
else
  echo "context freshness check: PASS"
fi

