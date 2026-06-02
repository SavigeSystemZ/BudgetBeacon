#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"
if [[ $# -lt 4 ]]; then
  echo "usage: $0 <target-repo> <agent-id> <scope-id> <ttl-minutes> [--role <role>] [--notes <text>]"
  exit 2
fi
repo="$1"; agent="$2"; scope="$3"; ttl="$4"; shift 4
role="implementation-worker"
notes=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --role) role="${2:-}"; shift 2 ;;
    --notes) notes="${2:-}"; shift 2 ;;
    *) echo "unknown arg: $1"; exit 2 ;;
  esac
done
[[ "$ttl" =~ ^[0-9]+$ ]] || { echo "ttl-minutes must be integer"; exit 2; }
dir="${repo}/_system/agent-state/locks"
mkdir -p "$dir"
scope_key="$(aiaast_sanitize_scope_key "$scope")"
lock="${dir}/${scope_key}.lock.json"
now="$(aiaast_iso_utc_now)"
exp="$(date -u -d "+${ttl} minutes" +"%Y-%m-%dT%H:%M:%SZ")"
# Atomic acquire (S22a WS2): exactly one of N racing acquirers wins the
# guard dir, eliminating the legacy check-then-create TOCTOU window. The
# fallback TTL (seconds) mirrors the lease so a guard cannot outlive it.
if ! aiaast_lock_acquire "$dir" "$scope_key" "$(( ttl * 60 ))"; then
  echo "lock exists: $lock"
  exit 1
fi
# Guard is held: if metadata write fails, release so we never leak a lock.
trap 'aiaast_lock_release "$dir" "$scope_key"' ERR
python3 - "$lock" "$scope" "$agent" "$role" "$now" "$exp" "$notes" <<'PY'
import json, sys
path, scope, agent, role, start, exp, notes = sys.argv[1:]
with open(path, "w", encoding="utf-8") as f:
    json.dump({
        "scope": scope,
        "owner_agent_id": agent,
        "owner_role": role,
        "lease_started_at": start,
        "lease_expires_at": exp,
        "notes": notes
    }, f, indent=2, sort_keys=True)
    f.write("\n")
PY
trap - ERR
echo "locked: $scope"

