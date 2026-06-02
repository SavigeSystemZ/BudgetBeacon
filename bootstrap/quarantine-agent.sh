#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: quarantine-agent.sh <repo-root> --agent-id ID --reason TEXT [--json]

Manually quarantine an active agent instance. Snapshots the lease, any
heartbeats, and every lock claimed by the lease into
_system/agent-state/quarantine/<agent_id>/ and appends a conflict record.

Operator primitive for incident response. See
_system/BLEED_EVENT_AND_INCIDENT_RESPONSE.md (S11) for the playbook.
EOF
}

TARGET=""; AGENT_ID=""; REASON=""; JSON_MODE=0
[[ $# -lt 1 ]] && { usage; exit 2; }
TARGET="$1"; shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent-id) AGENT_ID="${2:-}"; shift 2 ;;
    --reason)   REASON="${2:-}"; shift 2 ;;
    --json)     JSON_MODE=1; shift ;;
    -h|--help)  usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ ! -d "${TARGET}" ]] && { echo "target not found: ${TARGET}" >&2; exit 1; }
[[ -z "${AGENT_ID}" ]] && { echo "--agent-id required" >&2; exit 2; }
[[ -z "${REASON}" ]] && { echo "--reason required" >&2; exit 2; }

TARGET="$(cd -- "${TARGET}" && pwd)"

python3 - "${TARGET}" "${AGENT_ID}" "${REASON}" "${JSON_MODE}" <<'PY'
from __future__ import annotations
import json, shutil, sys
from datetime import datetime, timezone
from pathlib import Path

target = Path(sys.argv[1]).resolve()
agent_id = sys.argv[2]
reason = sys.argv[3]
json_mode = sys.argv[4] == "1"

state = target / "_system" / "agent-state"
pol_file = target / "_system" / "agent-instance-policy.json"
try:
    policy = json.loads(pol_file.read_text())
    layout = policy.get("state_layout", {})
except Exception:
    layout = {}

leases_dir     = target / layout.get("leases_dir", "_system/agent-state/leases")
locks_dir      = target / layout.get("locks_dir", "_system/agent-state/locks")
heartbeats_dir = target / layout.get("heartbeats_dir", "_system/agent-state/heartbeats")
quarantine_dir = target / layout.get("quarantine_dir", "_system/agent-state/quarantine")
conflicts_dir  = target / layout.get("conflicts_dir", "_system/agent-state/conflicts")

lease_path = leases_dir / f"{agent_id}.lease.json"
if not lease_path.is_file():
    msg = f"no active lease for {agent_id}"
    if json_mode: print(json.dumps({"ok": False, "script": "quarantine-agent.sh", "code": "no_lease", "message": msg}))
    else: sys.stderr.write(f"quarantine-agent.sh: {msg}\n")
    sys.exit(1)

try:
    lease = json.loads(lease_path.read_text())
except Exception as e:
    msg = f"lease unreadable: {e}"
    if json_mode: print(json.dumps({"ok": False, "script": "quarantine-agent.sh", "code": "unreadable", "message": msg}))
    else: sys.stderr.write(f"quarantine-agent.sh: {msg}\n")
    sys.exit(1)

q = quarantine_dir / agent_id
q.mkdir(parents=True, exist_ok=True)

now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
moved = []
shutil.move(str(lease_path), str(q / lease_path.name)); moved.append(lease_path.name)

hb = heartbeats_dir / f"{agent_id}.json"
if hb.is_file():
    shutil.move(str(hb), str(q / hb.name)); moved.append(hb.name)

for sc in lease.get("scopes", []) or []:
    lp = (target / sc.get("lock_path", "")).resolve()
    if lp.is_file() and locks_dir in lp.parents:
        shutil.move(str(lp), str(q / lp.name)); moved.append(lp.name)

conflicts_dir.mkdir(parents=True, exist_ok=True)
cf = conflicts_dir / f"{now.replace(':','-')}-manual-{agent_id}.md"
cf.write_text(
    f"# Manual quarantine: {agent_id}\n\n"
    f"- timestamp: {now}\n"
    f"- reason: {reason}\n"
    f"- snapshot: `{q.relative_to(target)}/`\n"
    f"- moved: {moved}\n"
)

(q / "quarantine-meta.json").write_text(json.dumps({
    "agent_id": agent_id,
    "quarantined_at": now,
    "reason": reason,
    "kind": "manual",
}, indent=2))

if json_mode:
    print(json.dumps({"ok": True, "script": "quarantine-agent.sh",
                      "agent_id": agent_id, "snapshot": str(q.relative_to(target)),
                      "moved": moved}))
else:
    print(f"quarantine-agent.sh: {agent_id} → {q.relative_to(target)} ({len(moved)} files)")
PY
