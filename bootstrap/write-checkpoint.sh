#!/usr/bin/env bash
set -euo pipefail

# write-checkpoint.sh
#
# Agent-neutral resume checkpoint writer. Any agent (Claude, Codex, Cursor,
# Gemini, local models, humans) can call this to persist mid-task state into
# `_system/checkpoints/` so another agent can resume cleanly after a rate
# limit, crash, handoff, or scheduled break.
#
# Writes:
#   _system/checkpoints/LATEST.json        (machine-readable, overwritten)
#   _system/checkpoints/LATEST.md          (human-readable briefing, overwritten)
#   _system/checkpoints/history/<ts>-<kind>.json   (append-only history)
#
# The companion reader is `bootstrap/resume-from-checkpoint.sh`.
#
# Design goals:
# - Agent-agnostic: every field is plain text or JSON; no agent-specific payload.
# - Crash-safe: writes are atomic (tempfile + mv).
# - Append-only history: the `history/` directory preserves every checkpoint.
# - Lightweight: no new runtime dependencies beyond python3 (already required
#   by the rest of the AIAST bootstrap layer).
# - Self-documenting: see _system/CHECKPOINT_PROTOCOL.md for full semantics.

usage() {
  cat <<'EOF'
Usage: write-checkpoint.sh [target-repo] [options]

Options:
  --kind <kind>          Checkpoint kind: session-start | mid-task | handoff |
                         rate-limit-save | milestone (default: mid-task)
  --agent <name>         Agent identifier (e.g. claude, codex, cursor, gemini,
                         windsurf, deepseek, local, human). Default: unknown
  --phase <text>         Short phrase describing the current work phase
  --objective <text>     One-sentence objective for the current session
  --completed <item>     A completed step (repeatable; each call appends one)
  --in-progress <text>   The step currently being worked on
  --next <item>          A pending next action (repeatable)
  --blocker <item>       A blocker (repeatable)
  --resume-file <path>   A file the next agent should load (repeatable)
  --resume-command <cmd> A concrete resume command for the next agent
  --confidence <level>   high | medium | low (default: medium)
  --note <text>          Freeform note (repeatable)
  --session-id <id>      Opaque session identifier
  --from-json <path>     Load a pre-built checkpoint JSON payload from disk
                         instead of building one from flags. All flag values
                         will override matching keys from the file.
  --validation-command <text>     Last validation command run
  --validation-result <text>      Last validation result string
  --validation-run-at <iso>       ISO-8601 timestamp of the last validation
  -h, --help                      Show this help

The first positional argument, if present, is treated as the target repo
root. When omitted, the script resolves the repo root by walking up from
the script's own directory (i.e. the repo that contains bootstrap/).

Examples:

  # Minimal mid-task checkpoint from Claude, with one next step
  bash bootstrap/write-checkpoint.sh . \
    --agent claude --kind mid-task \
    --phase "Refactoring auth middleware" \
    --next "Finish token revocation path" \
    --resume-file "src/auth/middleware.rs"

  # Rate-limit save: dump everything we know, then exit immediately
  bash bootstrap/write-checkpoint.sh . \
    --agent codex --kind rate-limit-save \
    --phase "Mid rollout of AIAST 1.23.0" \
    --completed "Ran update-template.sh on <ProjectX>" \
    L72:     --in-progress "Refreshing <ProjectX> handoff docs" \
    L73:     --next "Run system-doctor.sh on <ProjectX>" \
    L74:     --next "Commit and push <ProjectX> replay" \

    --confidence medium
EOF
}

KIND="mid-task"
AGENT="unknown"
PHASE=""
OBJECTIVE=""
IN_PROGRESS=""
RESUME_COMMAND=""
CONFIDENCE="medium"
SESSION_ID=""
FROM_JSON=""
VALIDATION_COMMAND=""
VALIDATION_RESULT=""
VALIDATION_RUN_AT=""
TARGET_REPO=""

COMPLETED=()
NEXT_ACTIONS=()
BLOCKERS=()
RESUME_FILES=()
NOTES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kind) KIND="${2:-}"; shift 2 ;;
    --agent) AGENT="${2:-}"; shift 2 ;;
    --phase) PHASE="${2:-}"; shift 2 ;;
    --objective) OBJECTIVE="${2:-}"; shift 2 ;;
    --completed) COMPLETED+=("${2:-}"); shift 2 ;;
    --in-progress) IN_PROGRESS="${2:-}"; shift 2 ;;
    --next) NEXT_ACTIONS+=("${2:-}"); shift 2 ;;
    --blocker) BLOCKERS+=("${2:-}"); shift 2 ;;
    --resume-file) RESUME_FILES+=("${2:-}"); shift 2 ;;
    --resume-command) RESUME_COMMAND="${2:-}"; shift 2 ;;
    --confidence) CONFIDENCE="${2:-}"; shift 2 ;;
    --note) NOTES+=("${2:-}"); shift 2 ;;
    --session-id) SESSION_ID="${2:-}"; shift 2 ;;
    --from-json) FROM_JSON="${2:-}"; shift 2 ;;
    --validation-command) VALIDATION_COMMAND="${2:-}"; shift 2 ;;
    --validation-result) VALIDATION_RESULT="${2:-}"; shift 2 ;;
    --validation-run-at) VALIDATION_RUN_AT="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *)
      if [[ -z "${TARGET_REPO}" ]]; then
        TARGET_REPO="$1"
        shift
      else
        echo "Unexpected argument: $1" >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "${TARGET_REPO}" ]]; then
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  TARGET_REPO="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
fi

if [[ ! -d "${TARGET_REPO}" ]]; then
  echo "Target repo does not exist: ${TARGET_REPO}" >&2
  exit 1
fi

RESOLVED_TARGET="$(cd -- "${TARGET_REPO}" && pwd)"
CHECKPOINTS_DIR="${RESOLVED_TARGET}/_system/checkpoints"
HISTORY_DIR="${CHECKPOINTS_DIR}/history"
mkdir -p "${HISTORY_DIR}"

export AIAST_CHECKPOINT_KIND="${KIND}"
export AIAST_CHECKPOINT_AGENT="${AGENT}"
export AIAST_CHECKPOINT_PHASE="${PHASE}"
export AIAST_CHECKPOINT_OBJECTIVE="${OBJECTIVE}"
export AIAST_CHECKPOINT_IN_PROGRESS="${IN_PROGRESS}"
export AIAST_CHECKPOINT_RESUME_COMMAND="${RESUME_COMMAND}"
export AIAST_CHECKPOINT_CONFIDENCE="${CONFIDENCE}"
export AIAST_CHECKPOINT_SESSION_ID="${SESSION_ID}"
export AIAST_CHECKPOINT_FROM_JSON="${FROM_JSON}"
export AIAST_CHECKPOINT_VALIDATION_COMMAND="${VALIDATION_COMMAND}"
export AIAST_CHECKPOINT_VALIDATION_RESULT="${VALIDATION_RESULT}"
export AIAST_CHECKPOINT_VALIDATION_RUN_AT="${VALIDATION_RUN_AT}"
export AIAST_CHECKPOINT_TARGET="${RESOLVED_TARGET}"
export AIAST_CHECKPOINT_DIR="${CHECKPOINTS_DIR}"
export AIAST_CHECKPOINT_HISTORY_DIR="${HISTORY_DIR}"

_aiaast_join_nul() { local IFS=$'\x01'; echo "$*"; }
export AIAST_CHECKPOINT_COMPLETED="$(_aiaast_join_nul "${COMPLETED[@]:-}")"
export AIAST_CHECKPOINT_NEXT="$(_aiaast_join_nul "${NEXT_ACTIONS[@]:-}")"
export AIAST_CHECKPOINT_BLOCKERS="$(_aiaast_join_nul "${BLOCKERS[@]:-}")"
export AIAST_CHECKPOINT_RESUME_FILES="$(_aiaast_join_nul "${RESUME_FILES[@]:-}")"
export AIAST_CHECKPOINT_NOTES="$(_aiaast_join_nul "${NOTES[@]:-}")"

python3 - <<'PY'
from __future__ import annotations

import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

SEP = "\x01"

def split_list(key: str) -> list[str]:
    raw = os.environ.get(key, "")
    if not raw:
        return []
    return [item for item in raw.split(SEP) if item]

target = Path(os.environ["AIAST_CHECKPOINT_TARGET"]).resolve()
ckpt_dir = Path(os.environ["AIAST_CHECKPOINT_DIR"])
history_dir = Path(os.environ["AIAST_CHECKPOINT_HISTORY_DIR"])

from_json = os.environ.get("AIAST_CHECKPOINT_FROM_JSON", "")
payload: dict = {}
if from_json:
    fp = Path(from_json)
    if not fp.exists():
        print(f"--from-json file not found: {from_json}", file=sys.stderr)
        sys.exit(1)
    try:
        payload = json.loads(fp.read_text())
    except json.JSONDecodeError as exc:
        print(f"--from-json file is not valid JSON: {exc}", file=sys.stderr)
        sys.exit(1)

def or_default(key: str, fallback):
    env_val = os.environ.get(key, "")
    if env_val:
        return env_val
    return payload.get(key_map.get(key, ""), fallback)

key_map = {
    "AIAST_CHECKPOINT_KIND": "kind",
    "AIAST_CHECKPOINT_AGENT": "agent",
    "AIAST_CHECKPOINT_PHASE": "phase",
    "AIAST_CHECKPOINT_OBJECTIVE": "objective",
    "AIAST_CHECKPOINT_IN_PROGRESS": "in_progress_step",
    "AIAST_CHECKPOINT_RESUME_COMMAND": "resume_command",
    "AIAST_CHECKPOINT_CONFIDENCE": "confidence",
    "AIAST_CHECKPOINT_SESSION_ID": "session_id",
    "AIAST_CHECKPOINT_VALIDATION_COMMAND": "validation_last_command",
    "AIAST_CHECKPOINT_VALIDATION_RESULT": "validation_last_result",
    "AIAST_CHECKPOINT_VALIDATION_RUN_AT": "validation_last_run_at",
}

kind = or_default("AIAST_CHECKPOINT_KIND", "mid-task")
valid_kinds = {"session-start", "mid-task", "handoff", "rate-limit-save", "milestone"}
if kind not in valid_kinds:
    print(
        f"Unknown --kind {kind!r}. Expected one of: {', '.join(sorted(valid_kinds))}",
        file=sys.stderr,
    )
    sys.exit(2)

now = datetime.now(timezone.utc).replace(microsecond=0)
created_at = now.isoformat().replace("+00:00", "Z")

def merge_list(env_key: str, json_key: str) -> list[str]:
    from_env = split_list(env_key)
    if from_env:
        return from_env
    val = payload.get(json_key, [])
    if isinstance(val, list):
        return [str(x) for x in val if str(x).strip()]
    return []

completed = merge_list("AIAST_CHECKPOINT_COMPLETED", "completed_steps")
next_actions = merge_list("AIAST_CHECKPOINT_NEXT", "next_actions")
blockers = merge_list("AIAST_CHECKPOINT_BLOCKERS", "blockers")
resume_files = merge_list("AIAST_CHECKPOINT_RESUME_FILES", "resume_files")
notes = merge_list("AIAST_CHECKPOINT_NOTES", "notes")

def read_version() -> str:
    v = target / "_system" / ".template-version"
    if v.exists():
        return v.read_text().strip()
    return "unknown"

def read_branch() -> str:
    head = target / ".git" / "HEAD"
    if not head.exists():
        return "unknown"
    try:
        line = head.read_text().strip()
    except OSError:
        return "unknown"
    if line.startswith("ref:"):
        return line.split("/", 2)[-1]
    return line[:12]

record = {
    "schema_version": "1",
    "kind": kind,
    "created_at": created_at,
    "agent": or_default("AIAST_CHECKPOINT_AGENT", "unknown"),
    "session_id": or_default("AIAST_CHECKPOINT_SESSION_ID", ""),
    "repo": str(target),
    "branch": read_branch(),
    "template_version": read_version(),
    "phase": or_default("AIAST_CHECKPOINT_PHASE", ""),
    "objective": or_default("AIAST_CHECKPOINT_OBJECTIVE", ""),
    "completed_steps": completed,
    "in_progress_step": or_default("AIAST_CHECKPOINT_IN_PROGRESS", ""),
    "next_actions": next_actions,
    "blockers": blockers,
    "resume_files": resume_files,
    "resume_command": or_default("AIAST_CHECKPOINT_RESUME_COMMAND", ""),
    "confidence": or_default("AIAST_CHECKPOINT_CONFIDENCE", "medium"),
    "validation_state": {
        "last_command": or_default("AIAST_CHECKPOINT_VALIDATION_COMMAND", ""),
        "last_result": or_default("AIAST_CHECKPOINT_VALIDATION_RESULT", ""),
        "last_run_at": or_default("AIAST_CHECKPOINT_VALIDATION_RUN_AT", ""),
    },
    "notes": notes,
}

def atomic_write(path: Path, content: str) -> None:
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(content)
    os.replace(tmp, path)

ckpt_dir.mkdir(parents=True, exist_ok=True)
history_dir.mkdir(parents=True, exist_ok=True)

latest_json = ckpt_dir / "LATEST.json"
latest_md = ckpt_dir / "LATEST.md"
ts_slug = now.strftime("%Y%m%dT%H%M%SZ")
history_json = history_dir / f"{ts_slug}-{kind}.json"

json_text = json.dumps(record, indent=2) + "\n"
atomic_write(latest_json, json_text)
history_json.write_text(json_text)

def render_md(rec: dict) -> str:
    lines: list[str] = []
    lines.append(f"# Latest Checkpoint")
    lines.append("")
    lines.append(f"- **Kind:** {rec['kind']}")
    lines.append(f"- **Created:** {rec['created_at']}")
    lines.append(f"- **Agent:** {rec['agent'] or 'unknown'}")
    if rec.get("session_id"):
        lines.append(f"- **Session id:** {rec['session_id']}")
    lines.append(f"- **Repo:** `{rec['repo']}`")
    lines.append(f"- **Branch:** `{rec['branch']}`")
    lines.append(f"- **Template version:** `{rec['template_version']}`")
    lines.append(f"- **Confidence:** {rec['confidence']}")
    lines.append("")
    if rec["phase"]:
        lines.append("## Phase")
        lines.append("")
        lines.append(rec["phase"])
        lines.append("")
    if rec["objective"]:
        lines.append("## Objective")
        lines.append("")
        lines.append(rec["objective"])
        lines.append("")
    if rec["completed_steps"]:
        lines.append("## Completed this session")
        lines.append("")
        for item in rec["completed_steps"]:
            lines.append(f"- {item}")
        lines.append("")
    if rec["in_progress_step"]:
        lines.append("## In-progress step")
        lines.append("")
        lines.append(rec["in_progress_step"])
        lines.append("")
    if rec["next_actions"]:
        lines.append("## Next actions (ordered)")
        lines.append("")
        for i, item in enumerate(rec["next_actions"], start=1):
            lines.append(f"{i}. {item}")
        lines.append("")
    if rec["blockers"]:
        lines.append("## Blockers")
        lines.append("")
        for item in rec["blockers"]:
            lines.append(f"- {item}")
        lines.append("")
    if rec["resume_files"]:
        lines.append("## Resume files")
        lines.append("")
        for item in rec["resume_files"]:
            lines.append(f"- `{item}`")
        lines.append("")
    if rec["resume_command"]:
        lines.append("## Resume command")
        lines.append("")
        lines.append(f"> {rec['resume_command']}")
        lines.append("")
    vs = rec.get("validation_state", {}) or {}
    if any(vs.values()):
        lines.append("## Validation state at checkpoint")
        lines.append("")
        if vs.get("last_command"):
            lines.append(f"- Last command: `{vs['last_command']}`")
        if vs.get("last_result"):
            lines.append(f"- Last result: {vs['last_result']}")
        if vs.get("last_run_at"):
            lines.append(f"- Last run at: {vs['last_run_at']}")
        lines.append("")
    if rec["notes"]:
        lines.append("## Notes")
        lines.append("")
        for item in rec["notes"]:
            lines.append(f"- {item}")
        lines.append("")
    lines.append("---")
    lines.append("")
    lines.append(
        "Written by `bootstrap/write-checkpoint.sh`. See "
        "`_system/CHECKPOINT_PROTOCOL.md` for how to read, write, and resume "
        "from checkpoints. The matching JSON payload lives at "
        "`_system/checkpoints/LATEST.json`, and every historical checkpoint "
        "is preserved under `_system/checkpoints/history/`."
    )
    lines.append("")
    return "\n".join(lines)

md_text = render_md(record)
atomic_write(latest_md, md_text)

print(f"checkpoint_written kind={record['kind']} agent={record['agent']} at={record['created_at']}")
print(f"checkpoint_latest_json={latest_json.relative_to(target)}")
print(f"checkpoint_latest_md={latest_md.relative_to(target)}")
print(f"checkpoint_history={history_json.relative_to(target)}")
PY
