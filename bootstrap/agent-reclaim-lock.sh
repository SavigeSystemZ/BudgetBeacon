#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"
if [[ $# -lt 4 ]]; then
  echo "usage: $0 <target-repo> <scope-id> <new-agent-id> <reason>"
  exit 2
fi
repo="$1"; scope="$2"; agent="$3"; reason="$4"
scope_key="$(aiaast_sanitize_scope_key "$scope")"
lock="${repo}/_system/agent-state/locks/${scope_key}.lock.json"
[[ -f "$lock" ]] || { echo "missing lock: $lock"; exit 1; }
python3 - "$lock" "$agent" <<'PY'
import json, sys
from datetime import datetime, timezone
path, agent = sys.argv[1:]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)
exp = datetime.strptime(data["lease_expires_at"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
if exp >= datetime.now(timezone.utc):
    raise SystemExit("lease not expired; cannot reclaim")
data["owner_agent_id"] = agent
data["lease_started_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
data["lease_expires_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, sort_keys=True)
    f.write("\n")
PY
ts="$(date -u +"%Y%m%dT%H%M%SZ")"
mkdir -p "${repo}/_system/agent-state/conflicts"
printf "reclaimed lock for scope=%s by=%s reason=%s\n" "$scope" "$agent" "$reason" > "${repo}/_system/agent-state/conflicts/${ts}-reclaim.md"
echo "reclaimed: $scope"
