#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage:
  release-agent.sh <repo-root> --agent-id ID [--source active|quarantine]
                   [--keep-snapshot] [--json]

Release an agent slot. By default releases an ACTIVE lease (agent shut down
cleanly): removes the lease, locks, and heartbeat. Pass --source quarantine
to clear a previously quarantined lease after operator review; quarantined
snapshots are deleted unless --keep-snapshot is set.

Operator primitive. Acceptance F-15 uses this implicitly through reaper +
re-claim, but operators may invoke it directly.
EOF
}

[[ $# -lt 1 ]] && { usage; exit 2; }
TARGET="$1"; shift
AGENT_ID=""; SOURCE="active"; KEEP=0; JSON_MODE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent-id)       AGENT_ID="${2:-}"; shift 2 ;;
    --source)         SOURCE="${2:-active}"; shift 2 ;;
    --keep-snapshot)  KEEP=1; shift ;;
    --json)           JSON_MODE=1; shift ;;
    -h|--help)        usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ ! -d "${TARGET}" ]] && { echo "target not found" >&2; exit 1; }
[[ -z "${AGENT_ID}" ]] && { echo "--agent-id required" >&2; exit 2; }
TARGET="$(cd -- "${TARGET}" && pwd)"

python3 - "${TARGET}" "${AGENT_ID}" "${SOURCE}" "${KEEP}" "${JSON_MODE}" <<'PY'
from __future__ import annotations
import json, shutil, sys
from datetime import datetime, timezone
from pathlib import Path

target = Path(sys.argv[1]).resolve()
agent_id = sys.argv[2]
source = sys.argv[3]
keep = sys.argv[4] == "1"
json_mode = sys.argv[5] == "1"

pol_file = target / "_system" / "agent-instance-policy.json"
try:
    policy = json.loads(pol_file.read_text()); layout = policy.get("state_layout", {})
except Exception:
    layout = {}

leases_dir     = target / layout.get("leases_dir", "_system/agent-state/leases")
locks_dir      = target / layout.get("locks_dir", "_system/agent-state/locks")
heartbeats_dir = target / layout.get("heartbeats_dir", "_system/agent-state/heartbeats")
quarantine_dir = target / layout.get("quarantine_dir", "_system/agent-state/quarantine")
conflicts_dir  = target / layout.get("conflicts_dir", "_system/agent-state/conflicts")

removed: list[str] = []

if source == "active":
    lease_path = leases_dir / f"{agent_id}.lease.json"
    if not lease_path.is_file():
        msg = f"no active lease for {agent_id}"
        if json_mode: print(json.dumps({"ok": False, "script": "release-agent.sh", "code": "no_lease", "message": msg}))
        else: sys.stderr.write(f"release-agent.sh: {msg}\n")
        sys.exit(1)
    try:
        lease = json.loads(lease_path.read_text())
    except Exception as e:
        if json_mode: print(json.dumps({"ok": False, "script": "release-agent.sh", "code": "unreadable", "message": str(e)}))
        else: sys.stderr.write(f"release-agent.sh: {e}\n")
        sys.exit(1)
    for sc in lease.get("scopes", []) or []:
        lp = (target / sc.get("lock_path", "")).resolve()
        if lp.is_file() and locks_dir in lp.parents:
            lp.unlink(); removed.append(lp.name)
    lease_path.unlink(); removed.append(lease_path.name)
    hb = heartbeats_dir / f"{agent_id}.json"
    if hb.is_file(): hb.unlink(); removed.append(hb.name)

elif source == "quarantine":
    q = quarantine_dir / agent_id
    if not q.is_dir():
        msg = f"no quarantine snapshot for {agent_id}"
        if json_mode: print(json.dumps({"ok": False, "script": "release-agent.sh", "code": "no_snapshot", "message": msg}))
        else: sys.stderr.write(f"release-agent.sh: {msg}\n")
        sys.exit(1)
    if keep:
        # mark released but keep files
        now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
        (q / "released-meta.json").write_text(json.dumps({"released_at": now, "kept": True}, indent=2))
        removed.append("(kept; marker added)")
    else:
        shutil.rmtree(str(q))
        removed.append(f"{agent_id}/ (entire snapshot)")

else:
    msg = f"unknown --source {source!r}; must be 'active' or 'quarantine'"
    if json_mode: print(json.dumps({"ok": False, "script": "release-agent.sh", "code": "bad_source", "message": msg}))
    else: sys.stderr.write(f"release-agent.sh: {msg}\n")
    sys.exit(1)

if json_mode:
    print(json.dumps({"ok": True, "script": "release-agent.sh",
                      "agent_id": agent_id, "source": source, "removed": removed}))
else:
    print(f"release-agent.sh: released {agent_id} from {source}; removed {len(removed)} file(s)")
PY
