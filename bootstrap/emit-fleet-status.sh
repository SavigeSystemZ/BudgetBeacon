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

lock_dir="${repo}/_system/agent-state/locks"
heartbeat_dir="${repo}/_system/agent-state/heartbeats"
locks=0; heartbeats=0
[[ -d "$lock_dir" ]] && locks="$( (rg --files "$lock_dir" -g "*.lock.json" || true) | wc -l )"
[[ -d "$heartbeat_dir" ]] && heartbeats="$( (rg --files "$heartbeat_dir" || true) | wc -l )"

if [[ "$json_mode" -eq 1 ]]; then
  aiaast_json_ok "{\"active_locks\":${locks},\"heartbeats\":${heartbeats}}" "emit-fleet-status.sh" "fleet"
else
  echo "fleet_status active_locks=${locks} heartbeats=${heartbeats}"
fi
