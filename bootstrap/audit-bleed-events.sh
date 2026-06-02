#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage:
  audit-bleed-events.sh <repo-root>
      [--since ISO-8601]
      [--severity critical|high|medium|low|critical+|high+|medium+]
      [--type TYPE [--type TYPE ...]]
      [--detected-by SCRIPT_NAME]
      [--agent-id ID] [--app-id ID]
      [--limit N]
      [--json]

Query the append-only bleed-event log under
_system/agent-state/audit/<YYYY-MM>.jsonl. The default (no filters)
shows every event newest-first.

`--severity X+` is shorthand for "X or worse" using the ordering
critical > high > medium > low. So `--severity high+` matches both
high and critical.

Exit code:
  0  one or more events matched
  1  no events matched (useful in CI: --severity high+ with exit-on-find)
  2  bad arguments
EOF
}

[[ $# -lt 1 ]] && { usage; exit 2; }
case "$1" in -h|--help) usage; exit 0 ;; esac

TARGET="$1"; shift
SINCE=""
SEVERITY=""
DETECTED_BY=""
AGENT_ID=""
APP_ID_FILTER=""
LIMIT="0"
JSON_MODE=0
TYPES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --since)        SINCE="${2:-}"; shift 2 ;;
    --severity)     SEVERITY="${2:-}"; shift 2 ;;
    --type)         TYPES+=("${2:-}"); shift 2 ;;
    --detected-by)  DETECTED_BY="${2:-}"; shift 2 ;;
    --agent-id)     AGENT_ID="${2:-}"; shift 2 ;;
    --app-id)       APP_ID_FILTER="${2:-}"; shift 2 ;;
    --limit)        LIMIT="${2:-0}"; shift 2 ;;
    --json)         JSON_MODE=1; shift ;;
    -h|--help)      usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ ! -d "${TARGET}" ]] && { echo "target not found: ${TARGET}" >&2; exit 1; }
TARGET="$(cd -- "${TARGET}" && pwd)"
TYPES_JSON="$(python3 -c "import json,sys; print(json.dumps(sys.argv[1:]))" "${TYPES[@]:-}")"

python3 - "${TARGET}" "${SINCE}" "${SEVERITY}" "${DETECTED_BY}" "${AGENT_ID}" "${APP_ID_FILTER}" "${LIMIT}" "${JSON_MODE}" "${TYPES_JSON}" <<'PY'
from __future__ import annotations
import json, sys
from pathlib import Path

(target_s, since, severity, detected_by, agent_id, app_id_filter,
 limit_s, json_mode_s, types_json) = sys.argv[1:10]
target = Path(target_s).resolve()
json_mode = json_mode_s == "1"
limit = int(limit_s)
types_filter = [t for t in json.loads(types_json) if t]

SEV_ORDER = {"low": 0, "medium": 1, "high": 2, "critical": 3}
sev_min = None
sev_exact = None
if severity:
    if severity.endswith("+"):
        base = severity[:-1]
        if base not in SEV_ORDER:
            sys.stderr.write(f"audit-bleed-events: unknown severity {severity!r}\n"); sys.exit(2)
        sev_min = SEV_ORDER[base]
    else:
        if severity not in SEV_ORDER:
            sys.stderr.write(f"audit-bleed-events: unknown severity {severity!r}\n"); sys.exit(2)
        sev_exact = severity

audit_dir = target / "_system" / "agent-state" / "audit"
events: list[dict] = []
if audit_dir.is_dir():
    files = sorted(p for p in audit_dir.iterdir() if p.name.endswith(".jsonl"))
    for f in files:
        for line in f.read_text().splitlines():
            line = line.strip()
            if not line: continue
            try:
                ev = json.loads(line)
            except Exception:
                continue
            ev["_source"] = f.name
            events.append(ev)

def matches(ev: dict) -> bool:
    if since and ev.get("ts", "") < since: return False
    if sev_exact is not None and ev.get("severity") != sev_exact: return False
    if sev_min is not None and SEV_ORDER.get(ev.get("severity"), -1) < sev_min: return False
    if types_filter and ev.get("type") not in types_filter: return False
    if detected_by and ev.get("detected_by") != detected_by: return False
    if agent_id and ev.get("agent_id") != agent_id: return False
    if app_id_filter and ev.get("app_id") != app_id_filter: return False
    return True

matched = [e for e in events if matches(e)]
# newest first
matched.sort(key=lambda e: e.get("ts", ""), reverse=True)
if limit > 0:
    matched = matched[:limit]

if json_mode:
    print(json.dumps({"ok": True, "script": "audit-bleed-events.sh",
                      "count": len(matched), "events": matched}))
else:
    for ev in matched:
        print(f"{ev.get('ts')}  [{ev.get('severity'):<8}] {ev.get('type'):<25} "
              f"by={ev.get('detected_by')} app={ev.get('app_id') or '-'} "
              f"agent={ev.get('agent_id') or '-'} :: {ev.get('observed_target') or ''}")
    if not matched:
        print("audit-bleed-events: no matches", file=sys.stderr)

sys.exit(0 if matched else 1)
PY
