#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"
if [[ $# -lt 4 ]]; then
  echo "usage: $0 <target-repo> <agent-id> <event-type> <summary>"
  exit 2
fi
repo="$1"; agent="$2"; type="$3"; summary="$4"
ts="$(aiaast_iso_utc_now)"
timeline="${repo}/_system/context/EVENT_TIMELINE.md"
jsonl="${repo}/_system/context/events.jsonl"
echo "- ${ts} | ${agent} | ${type} | ${summary}" >> "$timeline"
echo "{\"ts\":\"${ts}\",\"agent_id\":\"${agent}\",\"event_type\":\"${type}\",\"summary\":\"${summary}\"}" >> "$jsonl"
echo "event recorded"

