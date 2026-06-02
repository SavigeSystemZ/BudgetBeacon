#!/usr/bin/env bash
# stamp-tool-memory.sh
#
# Writer-side helper that prepends (or augments) a tool-memory isolation
# stamp on a _system/tool-memory/*.md file. Adapters call this BEFORE
# appending non-trivial content so the contract in
# _system/TOOL_MEMORY_ISOLATION_STAMP.md is satisfied at write time
# rather than caught after the fact by check-tool-memory-isolation.sh.
#
# Usage:
#   stamp-tool-memory.sh --adapter <name> --file <path> --agent-id <id> \
#                        [--target <repo-root>] [--json]
#
# Behavior:
#   * Refuses parent-template repos (role sentinel: parent_template_refusal).
#   * Requires _system/app-local-namespace.json (refusal: namespace_missing).
#   * agent_id must match ^[a-z][a-z0-9-]*-[0-9]{2,3}$ (agent_id_invalid).
#   * <file> must resolve under <target>/_system/tool-memory/ (file_outside_tool_memory).
#   * If file is missing, it's created with an H1 derived from basename.
#   * If no stamp present → prepend a fresh stamp (action=stamped).
#   * If stamp present with matching app_id and agent_id already listed → no-op (action=unchanged).
#   * If stamp present with matching app_id and new agent_id → augment to agents: list (action=augmented).
#   * If stamp present with diverging app_id → refuse (app_id_mismatch).
#
# JSON envelope on --json:
#   { "ok": bool,
#     "result": "stamp_tool_memory_ok"|"stamp_tool_memory_failed",
#     "action": "created"|"stamped"|"augmented"|"unchanged"|null,
#     "file": str, "app_id": str|null, "agent_id": str|null,
#     "adapter": str|null, "stamped_at": str|null,
#     "error": { "code": str, "detail": str }|null }

set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/lib/aiaast-lib.sh" ]]; then
  # shellcheck source=lib/aiaast-lib.sh
  source "${SCRIPT_DIR}/lib/aiaast-lib.sh" 2>/dev/null || true
fi

ADAPTER=""
FILE_ARG=""
AGENT_ID=""
TARGET=""
EMIT_JSON=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --adapter)   ADAPTER="$2";  shift 2 ;;
    --file)      FILE_ARG="$2"; shift 2 ;;
    --agent-id)  AGENT_ID="$2"; shift 2 ;;
    --target)    TARGET="$2";   shift 2 ;;
    --json)      EMIT_JSON=1;   shift ;;
    -h|--help)
      cat <<EOF
Usage: stamp-tool-memory.sh --adapter <name> --file <path> --agent-id <id> [--target <repo>] [--json]

Prepends or augments the tool-memory isolation stamp on a
_system/tool-memory/*.md file. See _system/TOOL_MEMORY_ISOLATION_STAMP.md.
EOF
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

emit_fail() {
  local code="$1" detail="$2"
  if [[ "${EMIT_JSON}" -eq 1 ]]; then
    python3 -c "import json,sys; print(json.dumps({
      'ok': False, 'result': 'stamp_tool_memory_failed', 'action': None,
      'file': sys.argv[1] or None, 'app_id': sys.argv[2] or None,
      'agent_id': sys.argv[3] or None, 'adapter': sys.argv[4] or None,
      'stamped_at': None,
      'error': {'code': sys.argv[5], 'detail': sys.argv[6]}}, indent=2))" \
      "${FILE_ARG}" "${APP_ID:-}" "${AGENT_ID}" "${ADAPTER}" "${code}" "${detail}"
  else
    echo "stamp_tool_memory_failed code=${code} detail=${detail}" >&2
  fi
  exit 1
}

[[ -z "${ADAPTER}"  ]] && { echo "stamp_tool_memory_failed code=adapter_required" >&2; exit 2; }
[[ -z "${FILE_ARG}" ]] && { echo "stamp_tool_memory_failed code=file_required"    >&2; exit 2; }
[[ -z "${AGENT_ID}" ]] && { echo "stamp_tool_memory_failed code=agent_id_required" >&2; exit 2; }

# Resolve TARGET. If absent, derive from FILE_ARG if absolute, else from script repo root.
if [[ -z "${TARGET}" ]]; then
  if [[ "${FILE_ARG}" = /* ]]; then
    # Walk up from file looking for _system/.aiast-role.json or app-local-namespace.json.
    d="$(dirname -- "${FILE_ARG}")"
    while [[ "${d}" != "/" ]]; do
      if [[ -f "${d}/_system/.aiast-role.json" || -f "${d}/_system/app-local-namespace.json" ]]; then
        TARGET="${d}"; break
      fi
      d="$(dirname -- "${d}")"
    done
  fi
  [[ -z "${TARGET}" ]] && TARGET="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
fi
TARGET="$(cd -- "${TARGET}" && pwd)"

# Role gate.
ROLE="unknown"
if [[ -f "${TARGET}/_system/.aiast-role.json" ]]; then
  ROLE="$(python3 -c "import json,sys
try: print(json.load(open(sys.argv[1])).get('role','unknown'))
except Exception: print('unknown')" "${TARGET}/_system/.aiast-role.json" 2>/dev/null || echo unknown)"
fi
if [[ "${ROLE}" == "parent-template" ]]; then
  emit_fail "parent_template_refusal" "target ${TARGET} has role=parent-template; tool-memory must remain empty stubs"
fi

# Namespace gate.
NS="${TARGET}/_system/app-local-namespace.json"
[[ -f "${NS}" ]] || emit_fail "namespace_missing" "expected ${NS}"
APP_ID="$(python3 -c "import json,sys
try: print(json.load(open(sys.argv[1])).get('app_id',''))
except Exception: print('')" "${NS}" 2>/dev/null || echo "")"
[[ -n "${APP_ID}" ]] || emit_fail "namespace_missing" "app_id missing in ${NS}"

# agent_id grammar.
if ! [[ "${AGENT_ID}" =~ ^[a-z][a-z0-9-]*-[0-9]{2,3}$ ]]; then
  emit_fail "agent_id_invalid" "agent_id=${AGENT_ID} violates [a-z][a-z0-9-]*-[0-9]{2,3}"
fi

# Resolve file path under <TARGET>/_system/tool-memory/.
TM_DIR="${TARGET}/_system/tool-memory"
if [[ "${FILE_ARG}" = /* ]]; then
  ABS_FILE="${FILE_ARG}"
else
  # Basename or relative — anchor under tool-memory dir.
  case "${FILE_ARG}" in
    */*) ABS_FILE="${TARGET}/${FILE_ARG#./}" ;;
    *)   ABS_FILE="${TM_DIR}/${FILE_ARG}" ;;
  esac
fi
ABS_FILE_REAL="$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "${ABS_FILE}")"
TM_DIR_REAL="$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "${TM_DIR}")"
case "${ABS_FILE_REAL}/" in
  "${TM_DIR_REAL}/"*) ;;
  *) emit_fail "file_outside_tool_memory" "${ABS_FILE_REAL} is not under ${TM_DIR_REAL}" ;;
esac

[[ -d "${TM_DIR}" ]] || mkdir -p "${TM_DIR}"

STAMPED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
export STM_FILE="${ABS_FILE_REAL}" STM_APP_ID="${APP_ID}" STM_AGENT_ID="${AGENT_ID}"
export STM_ADAPTER="${ADAPTER}" STM_STAMPED_AT="${STAMPED_AT}"

ACTION="$(python3 <<'PY'
import os, re, sys
from pathlib import Path

path = Path(os.environ["STM_FILE"])
app_id = os.environ["STM_APP_ID"]
agent_id = os.environ["STM_AGENT_ID"]
adapter = os.environ["STM_ADAPTER"]
stamped_at = os.environ["STM_STAMPED_AT"]

def derive_title(p):
    stem = p.stem
    if stem.endswith("-memory"):
        stem = stem[: -len("-memory")]
    words = [w.capitalize() for w in stem.replace("_", "-").split("-") if w]
    return "# " + " ".join(words) + " Memory"

action = None

if not path.exists():
    body = derive_title(path) + "\n\n" + (
        "<!-- tool-memory-isolation-stamp v1\n"
        f"app_id: {app_id}\n"
        f"agent_id: {agent_id}\n"
        f"set_at: {stamped_at}\n"
        f"set_by: {adapter}\n"
        "-->\n"
    )
    path.write_text(body, encoding="utf-8")
    print("created"); sys.exit(0)

lines = path.read_text(encoding="utf-8", errors="replace").splitlines()

# Find stamp block.
start = end = -1
for i, ln in enumerate(lines):
    if ln.strip().startswith("<!-- tool-memory-isolation-stamp"):
        start = i
        for j in range(i, len(lines)):
            if lines[j].strip().endswith("-->"):
                end = j; break
        break

def fresh_stamp_lines():
    return [
        "<!-- tool-memory-isolation-stamp v1",
        f"app_id: {app_id}",
        f"agent_id: {agent_id}",
        f"set_at: {stamped_at}",
        f"set_by: {adapter}",
        "-->",
    ]

if start == -1:
    # No stamp. Insert after H1 if present, else at top.
    insert_at = 0
    for i, ln in enumerate(lines):
        if ln.lstrip().startswith("# "):
            insert_at = i + 1
            # Skip a single blank line right after H1 to keep nice spacing.
            break
    new = lines[:insert_at] + [""] + fresh_stamp_lines() + [""] + lines[insert_at:]
    path.write_text("\n".join(new).rstrip() + "\n", encoding="utf-8")
    print("stamped"); sys.exit(0)

# Stamp exists — parse it.
existing = {}
agents = []
in_agents = False
for ln in lines[start + 1 : end]:
    s = ln.strip()
    if s.startswith("agents:"):
        in_agents = True; continue
    if in_agents and s.startswith("- "):
        agents.append(s[2:].strip()); continue
    in_agents = False
    if ":" in s:
        k, _, v = s.partition(":")
        existing[k.strip()] = v.strip()

if existing.get("app_id") != app_id:
    print("ERR app_id_mismatch", file=sys.stderr)
    sys.exit(7)

# Build full agent list (existing single agent_id + agents list).
current = []
if "agent_id" in existing:
    current.append(existing["agent_id"])
current.extend(agents)
current = [a for a in current if a]

if agent_id in current:
    print("unchanged"); sys.exit(0)

# Augment.
current.append(agent_id)
new_stamp = ["<!-- tool-memory-isolation-stamp v1",
             f"app_id: {app_id}",
             "agents:"]
for a in current:
    new_stamp.append(f"  - {a}")
new_stamp.append(f"set_at: {stamped_at}")
new_stamp.append(f"set_by: {adapter}")
new_stamp.append("-->")

new = lines[:start] + new_stamp + lines[end + 1 :]
path.write_text("\n".join(new).rstrip() + "\n", encoding="utf-8")
print("augmented")
PY
)" || {
  rc=$?
  if [[ ${rc} -eq 7 ]]; then
    emit_fail "app_id_mismatch" "existing stamp app_id does not equal active namespace ${APP_ID}"
  fi
  emit_fail "stamp_write_failed" "python stamp writer exited rc=${rc}"
}

if [[ "${EMIT_JSON}" -eq 1 ]]; then
  python3 -c "import json,sys; print(json.dumps({
    'ok': True, 'result': 'stamp_tool_memory_ok', 'action': sys.argv[1],
    'file': sys.argv[2], 'app_id': sys.argv[3], 'agent_id': sys.argv[4],
    'adapter': sys.argv[5], 'stamped_at': sys.argv[6], 'error': None}, indent=2))" \
    "${ACTION}" "${ABS_FILE_REAL}" "${APP_ID}" "${AGENT_ID}" "${ADAPTER}" "${STAMPED_AT}"
else
  echo "stamp_tool_memory_ok action=${ACTION} file=${ABS_FILE_REAL} app_id=${APP_ID} agent_id=${AGENT_ID} adapter=${ADAPTER}"
fi
exit 0
