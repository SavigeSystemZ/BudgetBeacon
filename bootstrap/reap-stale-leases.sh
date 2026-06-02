#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: reap-stale-leases.sh <repo-root> [--dry-run] [--json]

Sweep _system/agent-state/leases/ for expired leases. A lease is stale when
(now - heartbeat_at) > ttl + (grace_cycles * heartbeat_interval). Default
expired_action from agent-instance-policy.json is "quarantine": lease + its
locks + last heartbeat are atomically moved to
_system/agent-state/quarantine/<agent_id>/. A conflict record is appended
to _system/agent-state/conflicts/.

Options:
  --dry-run   Report what would be reaped without moving anything.
  --json      Emit machine-readable envelope on stdout.
EOF
}

[[ $# -lt 1 ]] && { usage; exit 2; }
TARGET="$1"; shift || true
DRY=0; JSON_MODE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    --json)    JSON_MODE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ ! -d "${TARGET}" ]] && { echo "target not found: ${TARGET}" >&2; exit 1; }
TARGET="$(cd -- "${TARGET}" && pwd)"

python3 - "${TARGET}" "${DRY}" "${JSON_MODE}" <<'PY'
from __future__ import annotations
import json, os, shutil, sys, time
from datetime import datetime, timezone
from pathlib import Path

target = Path(sys.argv[1]).resolve()
dry = sys.argv[2] == "1"
json_mode = sys.argv[3] == "1"

pol_file = target / "_system" / "agent-instance-policy.json"
state    = target / "_system" / "agent-state"

try:
    policy = json.loads(pol_file.read_text())
except Exception as e:
    if json_mode:
        print(json.dumps({"ok": False, "script": "reap-stale-leases.sh", "code": "missing_policy", "message": str(e)}))
    else:
        sys.stderr.write(f"reap-stale-leases.sh: missing policy: {e}\n")
    sys.exit(1)

layout = policy.get("state_layout", {})
leases_dir     = target / layout.get("leases_dir", "_system/agent-state/leases")
locks_dir      = target / layout.get("locks_dir", "_system/agent-state/locks")
heartbeats_dir = target / layout.get("heartbeats_dir", "_system/agent-state/heartbeats")
quarantine_dir = target / layout.get("quarantine_dir", "_system/agent-state/quarantine")
conflicts_dir  = target / layout.get("conflicts_dir", "_system/agent-state/conflicts")

leases_cfg = policy.get("leases", {})
ttl = int(leases_cfg.get("ttl_seconds", 300))
hb_int = int(leases_cfg.get("heartbeat_interval_seconds", 30))
grace_cycles = int(leases_cfg.get("grace_cycles", 1))
expired_action = leases_cfg.get("expired_action", "quarantine")

now_dt = datetime.now(timezone.utc).replace(microsecond=0)
now_iso = now_dt.isoformat().replace("+00:00", "Z")
now_epoch = int(now_dt.timestamp())

def parse_iso(s: str) -> int:
    try:
        return int(datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp())
    except Exception:
        return 0

reaped: list[dict] = []
kept:   list[dict] = []

if leases_dir.is_dir():
    for p in sorted(leases_dir.iterdir()):
        if not p.name.endswith(".lease.json"):
            continue
        try:
            d = json.loads(p.read_text())
        except Exception as e:
            reaped.append({"agent_id": p.stem, "reason": f"unreadable: {e}"})
            continue
        aid = d.get("agent_id", p.stem.replace(".lease",""))
        # Prefer heartbeat file mtime if present (fresher than lease's recorded heartbeat_at).
        hb_path = heartbeats_dir / f"{aid}.json"
        hb_epoch = 0
        if hb_path.is_file():
            try:
                hb_doc = json.loads(hb_path.read_text())
                hb_epoch = parse_iso(hb_doc.get("heartbeat_at", "")) or int(hb_path.stat().st_mtime)
            except Exception:
                hb_epoch = int(hb_path.stat().st_mtime)
        else:
            hb_epoch = parse_iso(d.get("heartbeat_at", "")) or parse_iso(d.get("lease_started_at", ""))
        stale_threshold = hb_epoch + ttl + grace_cycles * hb_int
        age = now_epoch - hb_epoch
        if hb_epoch == 0 or now_epoch > stale_threshold:
            entry = {"agent_id": aid, "age_seconds": age, "ttl": ttl,
                     "grace_cycles": grace_cycles, "lease_path": str(p.relative_to(target))}
            if not dry:
                if expired_action == "quarantine":
                    q = quarantine_dir / aid
                    q.mkdir(parents=True, exist_ok=True)
                    # Move lease
                    shutil.move(str(p), str(q / p.name))
                    # Move heartbeat if present
                    if hb_path.is_file():
                        shutil.move(str(hb_path), str(q / hb_path.name))
                    # Move locks
                    for sc in d.get("scopes", []) or []:
                        lp = (target / sc.get("lock_path", "")).resolve()
                        if lp.is_file() and locks_dir in lp.parents:
                            shutil.move(str(lp), str(q / lp.name))
                    # Conflict record
                    conflicts_dir.mkdir(parents=True, exist_ok=True)
                    cf = conflicts_dir / f"{now_iso.replace(':','-')}-reap-{aid}.md"
                    cf.write_text(
                        f"# Lease reap: {aid}\n\n"
                        f"- timestamp: {now_iso}\n"
                        f"- age_seconds: {age}\n"
                        f"- ttl: {ttl}\n"
                        f"- grace_cycles: {grace_cycles}\n"
                        f"- action: quarantine\n"
                        f"- snapshot: `{q.relative_to(target)}/`\n"
                    )
                    entry["quarantined_to"] = str(q.relative_to(target))
                elif expired_action == "delete":
                    p.unlink(missing_ok=True)
                    if hb_path.is_file(): hb_path.unlink(missing_ok=True)
                    for sc in d.get("scopes", []) or []:
                        lp = (target / sc.get("lock_path", "")).resolve()
                        if lp.is_file(): lp.unlink(missing_ok=True)
                elif expired_action == "release":
                    p.unlink(missing_ok=True)
                    if hb_path.is_file(): hb_path.unlink(missing_ok=True)
                    for sc in d.get("scopes", []) or []:
                        lp = (target / sc.get("lock_path", "")).resolve()
                        if lp.is_file(): lp.unlink(missing_ok=True)
            reaped.append(entry)
        else:
            kept.append({"agent_id": aid, "age_seconds": age})

out = {
    "ok": True, "script": "reap-stale-leases.sh", "dry_run": dry,
    "expired_action": expired_action,
    "reaped": reaped, "kept": kept, "now": now_iso,
}
if json_mode:
    print(json.dumps(out))
else:
    print(f"[reap-stale-leases] dry={dry} reaped={len(reaped)} kept={len(kept)} action={expired_action}")
    for r in reaped: print(f"  reaped: {r['agent_id']} age={r.get('age_seconds')}s")
PY
