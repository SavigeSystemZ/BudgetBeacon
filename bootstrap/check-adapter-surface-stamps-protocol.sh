#!/usr/bin/env bash
# check-adapter-surface-stamps-protocol.sh
#
# Asserts that every adapter surface file in the AIAST canonical set
# documents the tool-memory stamping protocol — i.e. references both:
#   - bootstrap/stamp-tool-memory.sh      (the writer-side helper)
#   - _system/TOOL_MEMORY_ISOLATION_STAMP.md  (the contract)
#
# This is the S12 adapter parity guard. The validator is intentionally
# narrow: it does NOT prescribe a specific phrase, only that both markers
# appear somewhere in each surface file. This keeps adapter wording
# tunable per-host while ensuring the protocol is discoverable wherever
# an agent first reads.
#
# JSON envelope on --json:
#   { "ok": bool,
#     "result": "adapter_surface_stamps_protocol_ok"|"adapter_surface_stamps_protocol_failed",
#     "summary": { "files": int, "passing": int, "missing": int },
#     "files": [
#       { "path": str, "has_helper_ref": bool, "has_stamp_doc_ref": bool, "ok": bool }
#     ],
#     "missing": [ { "path": str, "missing": [str,...] } ]
#   }

set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

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
Usage: check-adapter-surface-stamps-protocol.sh [TARGET] [--json]

Asserts every canonical adapter surface references the tool-memory stamp
helper and contract. See _system/TOOL_MEMORY_ISOLATION_STAMP.md.
EOF
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done
if [[ -z "${TARGET}" ]]; then
  TARGET="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
fi

export ASP_TARGET="${TARGET}"
export ASP_EMIT_JSON="${EMIT_JSON}"

python3 <<'PY'
import json, os, sys
from pathlib import Path

target = Path(os.environ["ASP_TARGET"])
emit_json = os.environ["ASP_EMIT_JSON"] == "1"

# Canonical adapter surface set. Every entry must exist in TARGET and must
# contain both protocol markers.
SURFACES = [
    "AGENTS.md",
    "CLAUDE.md",
    "CODEX.md",
    "GEMINI.md",
    "WINDSURF.md",
    "CURSOR.md",
    "COPILOT.md",
    "AIDER.md",
    "AGENT_ZERO.md",
    ".cursorrules",
    ".windsurfrules",
    ".github/copilot-instructions.md",
]

HELPER_MARKER   = "bootstrap/stamp-tool-memory.sh"
CONTRACT_MARKER = "_system/TOOL_MEMORY_ISOLATION_STAMP.md"

files = []
missing = []
passing = 0

for rel in SURFACES:
    p = target / rel
    if not p.exists():
        files.append({"path": rel, "has_helper_ref": False,
                      "has_stamp_doc_ref": False, "ok": False, "exists": False})
        missing.append({"path": rel, "missing": ["file_not_found"]})
        continue
    text = p.read_text(encoding="utf-8", errors="replace")
    has_helper   = HELPER_MARKER in text
    has_contract = CONTRACT_MARKER in text
    ok = has_helper and has_contract
    files.append({
        "path": rel, "has_helper_ref": has_helper,
        "has_stamp_doc_ref": has_contract, "ok": ok, "exists": True,
    })
    if ok:
        passing += 1
    else:
        miss = []
        if not has_helper:   miss.append("helper_ref")
        if not has_contract: miss.append("stamp_doc_ref")
        missing.append({"path": rel, "missing": miss})

ok_all = len(missing) == 0
env = {
    "ok": ok_all,
    "result": "adapter_surface_stamps_protocol_ok" if ok_all
              else "adapter_surface_stamps_protocol_failed",
    "summary": {
        "files": len(SURFACES),
        "passing": passing,
        "missing": len(missing),
    },
    "files": files,
    "missing": missing,
}

if emit_json:
    print(json.dumps(env, indent=2))
else:
    if ok_all:
        print(f"adapter_surface_stamps_protocol_ok files={len(SURFACES)} passing={passing}")
    else:
        print(f"adapter_surface_stamps_protocol_failed missing={len(missing)}", file=sys.stderr)
        for m in missing:
            print(f"  {m['path']}: missing " + ",".join(m["missing"]), file=sys.stderr)

sys.exit(0 if ok_all else 1)
PY
