#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"
if [[ $# -lt 3 ]]; then
  echo "usage: $0 <target-repo> <agent-id> <scope-id>"
  exit 2
fi
repo="$1"; agent="$2"; scope="$3"
scope_key="$(aiaast_sanitize_scope_key "$scope")"
locks_dir="${repo}/_system/agent-state/locks"
lock="${locks_dir}/${scope_key}.lock.json"
[[ -f "$lock" ]] || { echo "missing lock: $lock"; exit 1; }
if ! python3 - "$lock" "$agent" <<'PY'
import json,sys
path, agent = sys.argv[1:]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)
raise SystemExit(0 if data.get("owner_agent_id") == agent else 1)
PY
then
  echo "owner mismatch for lock: $lock"
  exit 1
fi
# Release both the legacy metadata file and the atomic guard dir (S22a WS2).
aiaast_lock_release "$locks_dir" "$scope_key"
echo "unlocked: $scope"

