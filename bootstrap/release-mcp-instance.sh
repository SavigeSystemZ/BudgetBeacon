#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: release-mcp-instance.sh <repo-root> --mcp-instance-id ID
                               [--source active|quarantine]
                               [--mode retire|delete]
                               [--reason TEXT] [--json]

Operator primitive.

  --source active (default): clean retire. Flips lifecycle.status to
    "retired", sets retired_at, appends a `retired` event. The record
    is KEPT in instances/ unless --mode delete is also given.

  --source quarantine: release a quarantined record. Default --mode is
    `retire` (move from quarantine/ back to instances/ with retired
    status). Pass --mode delete to remove the quarantined record after
    operator review.
EOF
}

[[ $# -lt 1 ]] && { usage; exit 2; }
case "$1" in -h|--help) usage; exit 0 ;; esac
TARGET="$1"; shift
INSTANCE_ID=""; SOURCE="active"; MODE="retire"; REASON=""; JSON_MODE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mcp-instance-id) INSTANCE_ID="${2:-}"; shift 2 ;;
    --source)          SOURCE="${2:-active}"; shift 2 ;;
    --mode)            MODE="${2:-retire}"; shift 2 ;;
    --reason)          REASON="${2:-}"; shift 2 ;;
    --json)            JSON_MODE=1; shift ;;
    -h|--help)         usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ ! -d "${TARGET}" ]] && { echo "target not found" >&2; exit 1; }
[[ -z "${INSTANCE_ID}" ]] && { echo "--mcp-instance-id required" >&2; exit 2; }
TARGET="$(cd -- "${TARGET}" && pwd)"

python3 - "${TARGET}" "${INSTANCE_ID}" "${SOURCE}" "${MODE}" "${REASON}" "${JSON_MODE}" <<'PY'
from __future__ import annotations
import json, sys
from datetime import datetime, timezone
from pathlib import Path

target = Path(sys.argv[1]).resolve()
instance_id = sys.argv[2]
source = sys.argv[3]
mode = sys.argv[4]
reason = sys.argv[5]
json_mode = sys.argv[6] == "1"

def fail(code, msg):
    if json_mode:
        print(json.dumps({"ok": False, "script": "release-mcp-instance.sh",
                          "error": {"code": code, "message": msg}}))
    else:
        sys.stderr.write(f"release-mcp-instance.sh: {code}: {msg}\n")
    sys.exit(1)

if source not in ("active", "quarantine"):
    fail("bad_source", f"--source must be active|quarantine; got {source!r}")
if mode not in ("retire", "delete"):
    fail("bad_mode", f"--mode must be retire|delete; got {mode!r}")

policy_file = target / "_system" / "mcp-instance-policy.json"
try:
    policy = json.loads(policy_file.read_text()) if policy_file.is_file() else {}
except Exception as e:
    fail("missing_policy", f"unreadable: {e}")
reg = policy.get("registry") or {}
instances_dir  = target / reg.get("instances_dir",  "_system/mcp/instances")
quarantine_dir = target / reg.get("quarantine_dir", "_system/mcp/instances/quarantine")
prov_log       = target / reg.get("provenance_log", "_system/mcp/runtime/mcp-server-provenance.jsonl")

safe = instance_id.replace(":", "__")
src = (instances_dir if source == "active" else quarantine_dir) / f"{safe}.json"
if not src.is_file():
    fail("no_record", f"no record at {src.relative_to(target)}")

try:
    rec = json.loads(src.read_text())
except Exception as e:
    fail("unreadable", f"{e}")

now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
lc = rec.setdefault("lifecycle", {})

action = "retired" if mode == "retire" else "deleted"

if mode == "delete":
    src.unlink()
    dst = None
else:
    lc["status"] = "retired"
    lc["retired_at"] = now
    lc.setdefault("events", []).append({
        "ts": now, "kind": "retired",
        "by": "release-mcp-instance.sh", "source": source, "reason": reason or "",
    })
    dst = instances_dir / f"{safe}.json"
    if source == "quarantine":
        # Move back to instances/ with retired status.
        if dst.exists():
            fail("conflict", f"{dst.relative_to(target)} already exists (cannot move from quarantine)")
        instances_dir.mkdir(parents=True, exist_ok=True)
        with open(dst, "w") as fh:
            json.dump(rec, fh, indent=2); fh.write("\n")
        src.unlink()
    else:
        # rewrite in place
        with open(dst, "w") as fh:
            json.dump(rec, fh, indent=2); fh.write("\n")

prov_log.parent.mkdir(parents=True, exist_ok=True)
with open(prov_log, "a") as fh:
    fh.write(json.dumps({"ts": now, "mcp_instance_id": instance_id,
                         "kind": action, "source": source,
                         "reason": reason or ""}) + "\n")

if json_mode:
    print(json.dumps({"ok": True, "script": "release-mcp-instance.sh",
                      "mcp_instance_id": instance_id,
                      "action": action, "source": source,
                      "result_path": (None if dst is None else str(dst.relative_to(target)))}))
else:
    if mode == "delete":
        print(f"release-mcp-instance.sh: deleted {instance_id} (from {source})")
    else:
        print(f"release-mcp-instance.sh: retired {instance_id} (from {source}) → {dst.relative_to(target)}")
PY
