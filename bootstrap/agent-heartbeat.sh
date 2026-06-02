#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"
if [[ $# -lt 2 ]]; then
  echo "usage: $0 <target-repo> <agent-id>"
  exit 2
fi
repo="$1"; agent="$2"
dir="${repo}/_system/agent-state/heartbeats"
mkdir -p "$dir"
now="$(aiaast_iso_utc_now)"
echo "{\"agent_id\":\"$agent\",\"heartbeat_at\":\"$now\"}" > "${dir}/${agent}.json"
echo "heartbeat: $agent"

