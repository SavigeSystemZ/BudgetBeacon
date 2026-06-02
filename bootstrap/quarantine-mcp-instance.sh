#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: quarantine-mcp-instance.sh <repo-root> --mcp-instance-id ID
                                  --reason TEXT [--json]

Operator primitive. Moves an MCP instance record from
_system/mcp/instances/<safe>.json to
_system/mcp/instances/quarantine/<safe>.json, flips lifecycle.status to
"quarantined", appends a `quarantined` event, and appends a quarantine
entry to the provenance log.

See _system/mcp/MCP_INSTANCE_REGISTRY_PROTOCOL.md §"quarantine".
EOF
}

[[ $# -lt 1 ]] && { usage; exit 2; }
case "$1" in -h|--help) usage; exit 0 ;; esac
TARGET="$1"; shift
INSTANCE_ID=""; REASON=""; JSON_MODE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mcp-instance-id) INSTANCE_ID="${2:-}"; shift 2 ;;
    --reason)          REASON="${2:-}"; shift 2 ;;
    --json)            JSON_MODE=1; shift ;;
    -h|--help)         usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ ! -d "${TARGET}" ]] && { echo "target not found" >&2; exit 1; }
[[ -z "${INSTANCE_ID}" ]] && { echo "--mcp-instance-id required" >&2; exit 2; }
[[ -z "${REASON}" ]] && { echo "--reason required" >&2; exit 2; }
TARGET="$(cd -- "${TARGET}" && pwd)"

python3 - "${TARGET}" "${INSTANCE_ID}" "${REASON}" "${JSON_MODE}" <<'PY'
from __future__ import annotations
import json, shutil, sys
from datetime import datetime, timezone
from pathlib import Path

target = Path(sys.argv[1]).resolve()
instance_id = sys.argv[2]
reason = sys.argv[3]
json_mode = sys.argv[4] == "1"

def fail(code, msg):
    if json_mode:
        print(json.dumps({"ok": False, "script": "quarantine-mcp-instance.sh",
                          "error": {"code": code, "message": msg}}))
    else:
        sys.stderr.write(f"quarantine-mcp-instance.sh: {code}: {msg}\n")
    sys.exit(1)

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
src = instances_dir / f"{safe}.json"
if not src.is_file():
    fail("no_record", f"no instance record at {src.relative_to(target)}")

try:
    rec = json.loads(src.read_text())
except Exception as e:
    fail("unreadable", f"{e}")

now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
lc = rec.setdefault("lifecycle", {})
lc["status"] = "quarantined"
lc.setdefault("events", []).append({
    "ts": now, "kind": "quarantined",
    "by": "quarantine-mcp-instance.sh", "reason": reason,
})

quarantine_dir.mkdir(parents=True, exist_ok=True)
dst = quarantine_dir / f"{safe}.json"
if dst.exists():
    fail("already_quarantined", f"{dst.relative_to(target)} already exists")

with open(dst, "w") as fh:
    json.dump(rec, fh, indent=2); fh.write("\n")
src.unlink()

prov_log.parent.mkdir(parents=True, exist_ok=True)
with open(prov_log, "a") as fh:
    fh.write(json.dumps({"ts": now, "mcp_instance_id": instance_id,
                         "kind": "quarantine", "reason": reason}) + "\n")

if json_mode:
    print(json.dumps({"ok": True, "script": "quarantine-mcp-instance.sh",
                      "mcp_instance_id": instance_id,
                      "moved": {"from": str(src.relative_to(target)),
                                "to": str(dst.relative_to(target))}}))
else:
    print(f"quarantine-mcp-instance.sh: {instance_id} → {dst.relative_to(target)}")
PY
