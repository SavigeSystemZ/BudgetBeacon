#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: verify-mcp-provenance.sh <repo-root> [--mcp-instance-id ID]
                                [--strict] [--json]

Read-only. Compares each registered MCP instance's server_package
(package id, version, integrity) against the latest matching entry in
the provenance log (_system/mcp/runtime/mcp-server-provenance.jsonl).

Any mismatch is a `provenance-drift` event (F-17). Under --strict, drift
causes a non-zero exit; otherwise drift is reported but exit is 0.

Records that do not yet have a provenance log entry are reported as
`no-provenance-baseline`; that is not drift, just an unverifiable
baseline.
EOF
}

[[ $# -lt 1 ]] && { usage; exit 2; }
case "$1" in -h|--help) usage; exit 0 ;; esac
TARGET="$1"; shift
INSTANCE_ID=""
STRICT=0
JSON_MODE=0
EMIT_BLEED=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mcp-instance-id)   INSTANCE_ID="${2:-}"; shift 2 ;;
    --strict)            STRICT=1; shift ;;
    --json)              JSON_MODE=1; shift ;;
    --emit-bleed-events) EMIT_BLEED=1; shift ;;
    -h|--help)           usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ ! -d "${TARGET}" ]] && { echo "target not found: ${TARGET}" >&2; exit 1; }
TARGET="$(cd -- "${TARGET}" && pwd)"

export AIAST_EMIT_BLEED="${EMIT_BLEED}"
python3 - "${TARGET}" "${INSTANCE_ID}" "${STRICT}" "${JSON_MODE}" <<'PY'
from __future__ import annotations
import json, os, secrets, sys
from datetime import datetime, timezone
from pathlib import Path

target = Path(sys.argv[1]).resolve()
want_id = sys.argv[2]
strict = sys.argv[3] == "1"
json_mode = sys.argv[4] == "1"

def _bleed(severity: str, scope_path: str, *, observed=None, context=None,
           remediation_action: str = "notify") -> None:
    if os.environ.get("AIAST_EMIT_BLEED") != "1": return
    try:
        ns_file = target / "_system" / "app-local-namespace.json"
        app_id = host_fp = allowed_root = None
        if ns_file.is_file():
            n = json.loads(ns_file.read_text())
            app_id = n.get("app_id"); host_fp = n.get("host_fingerprint_id")
            allowed_root = n.get("repo_root_realpath")
        now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
        ev = {
            "event_id": f"evt_{secrets.token_hex(13)}",
            "ts": now, "severity": severity, "type": "provenance-drift",
            "detected_by": "verify-mcp-provenance.sh",
            "agent_id": None, "app_id": app_id, "host_fingerprint_id": host_fp,
            "scope": {"path": scope_path, "operation": "detect"},
            "intended_boundary": {"allowed_repo_root": allowed_root},
            "observed_target": observed,
            "evidence_refs": [],
            "remediation": {"action": remediation_action, "by": "verify-mcp-provenance.sh", "ts": now},
        }
        if context: ev["context"] = context
        audit = target / "_system" / "agent-state" / "audit"
        audit.mkdir(parents=True, exist_ok=True)
        with open(audit / f"{now[:7]}.jsonl", "a") as fh:
            fh.write(json.dumps(ev, separators=(",", ":")) + "\n")
    except Exception:
        pass

policy_file = target / "_system" / "mcp-instance-policy.json"
try:
    policy = json.loads(policy_file.read_text())
except Exception:
    policy = {}
reg = policy.get("registry") or {}
instances_dir = target / reg.get("instances_dir",  "_system/mcp/instances")
prov_log      = target / reg.get("provenance_log", "_system/mcp/runtime/mcp-server-provenance.jsonl")

# Load latest provenance entry per mcp_instance_id (last register/refresh wins).
latest: dict[str, dict] = {}
if prov_log.is_file():
    for line in prov_log.read_text().splitlines():
        line = line.strip()
        if not line: continue
        try:
            ev = json.loads(line)
        except Exception:
            continue
        mid = ev.get("mcp_instance_id")
        if not mid: continue
        if ev.get("kind") in ("register", "refresh"):
            latest[mid] = ev

records: list[dict] = []
if instances_dir.is_dir():
    for p in sorted(instances_dir.iterdir()):
        if p.is_dir(): continue
        if not p.name.endswith(".json"): continue
        if p.name == ".gitkeep": continue
        try:
            d = json.loads(p.read_text())
        except Exception as e:
            records.append({"path": str(p.relative_to(target)), "error": f"unreadable: {e}"})
            continue
        records.append({"path": str(p.relative_to(target)), "record": d})

reports: list[dict] = []
drift = 0
missing_baseline = 0

for r in records:
    if "error" in r:
        reports.append({"path": r["path"], "status": "unreadable", "detail": r["error"]})
        continue
    rec = r["record"]
    mid = rec.get("mcp_instance_id", "")
    if want_id and mid != want_id:
        continue
    pkg = rec.get("server_package") or {}
    base = latest.get(mid)
    if base is None:
        missing_baseline += 1
        reports.append({"path": r["path"], "mcp_instance_id": mid,
                        "status": "no-provenance-baseline"})
        continue
    bpkg = base.get("package") or {}
    diff = {}
    for k in ("id", "version", "integrity"):
        if pkg.get(k) != bpkg.get(k):
            diff[k] = {"record": pkg.get(k), "baseline": bpkg.get(k)}
    if diff:
        drift += 1
        reports.append({"path": r["path"], "mcp_instance_id": mid,
                        "status": "provenance-drift", "diff": diff,
                        "baseline_ts": base.get("ts")})
        _bleed("medium", r["path"],
               observed=str(diff),
               context={"fault": "F-17", "mcp_instance_id": mid,
                        "baseline_ts": base.get("ts")},
               remediation_action="notify")
    else:
        reports.append({"path": r["path"], "mcp_instance_id": mid,
                        "status": "ok", "baseline_ts": base.get("ts")})

out = {
    "ok": (drift == 0) or (not strict),
    "script": "verify-mcp-provenance.sh",
    "strict": strict,
    "summary": {
        "records": len(records),
        "drift": drift,
        "no_baseline": missing_baseline,
        "ok": sum(1 for r in reports if r.get("status") == "ok"),
    },
    "reports": reports,
}

if json_mode:
    print(json.dumps(out))
else:
    print(f"verify-mcp-provenance: records={len(records)} drift={drift} no_baseline={missing_baseline}")
    for r in reports:
        if r.get("status") in ("ok", "no-provenance-baseline"):
            print(f"  [{r['status']}] {r.get('mcp_instance_id') or r['path']}")
        else:
            print(f"  [{r['status']}] {r.get('mcp_instance_id') or r['path']} :: "
                  f"{r.get('diff') or r.get('detail')}")

sys.exit(0 if out["ok"] else 1)
PY
