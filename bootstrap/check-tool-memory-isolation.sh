#!/usr/bin/env bash
# check-tool-memory-isolation.sh
#
# Validates _system/tool-memory/*.md against the isolation-stamp contract
# defined in _system/TOOL_MEMORY_ISOLATION_STAMP.md.
#
# Dual-mode:
#   parent-template repo  → every tool-memory file MUST be a trivial stub
#                           (empty / title-only). Non-trivial content is
#                           a contract violation regardless of stamp.
#   downstream-app repo   → every non-trivial tool-memory file MUST carry
#                           a valid stamp whose app_id matches the active
#                           _system/app-local-namespace.json#/app_id.
#
# JSON envelope on --json:
#   { "ok": bool,
#     "result": "tool_memory_isolation_ok" | "tool_memory_isolation_failed",
#     "role": "downstream-app" | "parent-template" | "unknown",
#     "summary": { "files": int, "trivial": int, "stamped": int, "violations": int },
#     "violations": [ { "file": str, "code": str, "detail": str } ],
#     "app_id": str|null
#   }

set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source the shared lib if present (we rely only on its presence for
# convention — the script does its own envelope writing).
if [[ -f "${SCRIPT_DIR}/lib/aiaast-lib.sh" ]]; then
  # shellcheck source=lib/aiaast-lib.sh
  source "${SCRIPT_DIR}/lib/aiaast-lib.sh" 2>/dev/null || true
fi

TARGET="${1:-}"
EMIT_JSON=0
shift_count=0
if [[ -n "${TARGET}" && "${TARGET}" != --* ]]; then
  shift_count=1
fi
shift "${shift_count}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) EMIT_JSON=1; shift ;;
    -h|--help)
      cat <<EOF
Usage: check-tool-memory-isolation.sh [TARGET] [--json]

  TARGET   Path to repo root (defaults to the repo containing this script).
  --json   Emit JSON envelope.
EOF
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done
if [[ -z "${TARGET}" ]]; then
  TARGET="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
fi

if [[ ! -d "${TARGET}/_system/tool-memory" ]]; then
  echo "tool_memory_isolation_failed reason=missing_tool_memory_dir path=${TARGET}/_system/tool-memory" >&2
  exit 2
fi

ROLE="unknown"
if [[ -f "${TARGET}/_system/.aiast-role.json" ]]; then
  ROLE="$(python3 -c "import json,sys
try: print(json.load(open(sys.argv[1])).get('role','unknown'))
except Exception: print('unknown')" "${TARGET}/_system/.aiast-role.json" 2>/dev/null || echo unknown)"
fi

APP_ID=""
if [[ -f "${TARGET}/_system/app-local-namespace.json" ]]; then
  APP_ID="$(python3 -c "import json,sys
try: print(json.load(open(sys.argv[1])).get('app_id',''))
except Exception: print('')" "${TARGET}/_system/app-local-namespace.json" 2>/dev/null || echo "")"
fi

# Walk tool-memory files and classify via python (JSON-friendly).
export TM_TARGET="${TARGET}"
export TM_ROLE="${ROLE}"
export TM_APP_ID="${APP_ID}"
export TM_EMIT_JSON="${EMIT_JSON}"

python3 <<'PY'
import json, os, re, sys
from pathlib import Path

target = Path(os.environ["TM_TARGET"])
role = os.environ["TM_ROLE"]
app_id = os.environ["TM_APP_ID"]
emit_json = os.environ["TM_EMIT_JSON"] == "1"

tm_dir = target / "_system" / "tool-memory"
files = sorted(p for p in tm_dir.glob("*.md") if p.name != "README.md")

AGENT_ID_RE = re.compile(r"^[a-z][a-z0-9-]*-[0-9]{2,3}$")
ISO_Z_RE = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$")

def classify(path):
    """Return (is_trivial, lines_outside_stamp_count, raw_lines)."""
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    # Strip the stamp block if present.
    in_stamp = False
    body = []
    saw_title = False
    for ln in lines:
        s = ln.strip()
        if not saw_title and s.startswith("# "):
            saw_title = True
            continue
        if s.startswith("<!-- tool-memory-isolation-stamp"):
            in_stamp = True
            continue
        if in_stamp:
            if s.endswith("-->"):
                in_stamp = False
            continue
        if not s:
            continue
        if s.startswith("<!--") and s.endswith("-->"):
            continue
        body.append(ln)
    return (len(body) == 0, len(body), lines)

def parse_stamp(lines):
    """Extract stamp fields. Returns dict or None if absent."""
    in_stamp = False
    fields = {}
    agents = []
    in_agents = False
    for ln in lines:
        s = ln.strip()
        if s.startswith("<!-- tool-memory-isolation-stamp"):
            in_stamp = True
            continue
        if in_stamp:
            if s.endswith("-->"):
                in_stamp = False
                break
            if s.startswith("agents:"):
                in_agents = True
                continue
            if in_agents and s.startswith("- "):
                agents.append(s[2:].strip())
                continue
            in_agents = False
            if ":" in s:
                k, _, v = s.partition(":")
                fields[k.strip()] = v.strip()
    if not fields and not agents:
        return None
    if agents:
        fields["agents"] = agents
    return fields

violations = []
stamped = 0
trivial = 0

for f in files:
    is_trivial, body_len, raw_lines = classify(f)
    if is_trivial:
        trivial += 1
        if role == "parent-template":
            continue  # template requires empty stubs — OK
        continue  # downstream: empty stub is fine
    # Non-trivial content.
    if role == "parent-template":
        violations.append({
            "file": str(f.relative_to(target)),
            "code": "parent_template_has_content",
            "detail": f"non-trivial body lines: {body_len}",
        })
        continue
    stamp = parse_stamp(raw_lines)
    if stamp is None:
        violations.append({
            "file": str(f.relative_to(target)),
            "code": "stamp_missing",
            "detail": "no <!-- tool-memory-isolation-stamp v1 ... --> block",
        })
        continue
    # Validate required fields.
    required = ["app_id", "set_at", "set_by"]
    missing = [k for k in required if k not in stamp]
    has_agent = "agent_id" in stamp or stamp.get("agents")
    if not has_agent:
        missing.append("agent_id|agents")
    if missing:
        violations.append({
            "file": str(f.relative_to(target)),
            "code": "stamp_malformed",
            "detail": "missing fields: " + ",".join(missing),
        })
        continue
    if not ISO_Z_RE.match(stamp.get("set_at", "")):
        violations.append({
            "file": str(f.relative_to(target)),
            "code": "stamp_malformed",
            "detail": f"set_at not ISO-8601 Z: {stamp.get('set_at')}",
        })
        continue
    if app_id and stamp.get("app_id") != app_id:
        violations.append({
            "file": str(f.relative_to(target)),
            "code": "app_id_mismatch",
            "detail": f"stamp.app_id={stamp.get('app_id')} vs active={app_id}",
        })
        continue
    agent_ids = stamp.get("agents") or [stamp.get("agent_id", "")]
    bad = [a for a in agent_ids if not AGENT_ID_RE.match(a or "")]
    if bad:
        violations.append({
            "file": str(f.relative_to(target)),
            "code": "agent_id_invalid",
            "detail": "violates [a-z][a-z0-9-]*-[0-9]{2,3}: " + ",".join(bad),
        })
        continue
    stamped += 1

ok = len(violations) == 0
env = {
    "ok": ok,
    "result": "tool_memory_isolation_ok" if ok else "tool_memory_isolation_failed",
    "role": role,
    "app_id": app_id or None,
    "summary": {
        "files": len(files),
        "trivial": trivial,
        "stamped": stamped,
        "violations": len(violations),
    },
    "violations": violations,
}

if emit_json:
    print(json.dumps(env, indent=2))
else:
    if ok:
        print(f"tool_memory_isolation_ok files={len(files)} trivial={trivial} stamped={stamped} role={role}")
    else:
        print(f"tool_memory_isolation_failed violations={len(violations)} role={role}", file=sys.stderr)
        for v in violations:
            print(f"  {v['file']}: {v['code']} — {v['detail']}", file=sys.stderr)

sys.exit(0 if ok else 1)
PY
