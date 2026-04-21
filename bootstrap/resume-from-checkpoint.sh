#!/usr/bin/env bash
set -euo pipefail

# resume-from-checkpoint.sh
#
# Print a concise resume briefing assembled from the latest checkpoint under
# `_system/checkpoints/`. Designed to be pasted (or piped) into the startup
# context of any agent CLI so the incoming agent begins productive work
# immediately after a rate-limit, crash, or handoff.
#
# By default, reads `_system/checkpoints/LATEST.json` and renders a human
# briefing to stdout. Use `--format json` to emit the raw payload for
# machine consumers, or `--format md` to get the pre-rendered Markdown from
# `LATEST.md` (trimmed to the essentials).
#
# The companion writer is `bootstrap/write-checkpoint.sh`.

usage() {
  cat <<'EOF'
Usage: resume-from-checkpoint.sh [target-repo] [options]

Options:
  --format <human|md|json>   Output format (default: human)
  --history                  List every historical checkpoint under
                             _system/checkpoints/history/ instead of the
                             latest briefing
  --json-path                Print the absolute path to LATEST.json and exit
  --md-path                  Print the absolute path to LATEST.md and exit
  -h, --help                 Show this help

The first positional argument, if present, is treated as the target repo
root. When omitted, the script resolves the repo root by walking up from
the script's own directory.

Exit codes:
  0  Briefing printed (or path returned)
  3  No checkpoint exists yet (LATEST.json missing)
  4  LATEST.json is present but malformed

Examples:

  # Print the briefing for the current repo
  bash bootstrap/resume-from-checkpoint.sh .

  # Pipe the raw JSON into another tool
  bash bootstrap/resume-from-checkpoint.sh . --format json | jq .next_actions

  # Show every past checkpoint oldest-to-newest
  bash bootstrap/resume-from-checkpoint.sh . --history
EOF
}

FORMAT="human"
HISTORY=0
TARGET_REPO=""
PRINT_JSON_PATH=0
PRINT_MD_PATH=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --format) FORMAT="${2:-human}"; shift 2 ;;
    --history) HISTORY=1; shift ;;
    --json-path) PRINT_JSON_PATH=1; shift ;;
    --md-path) PRINT_MD_PATH=1; shift ;;
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
LATEST_JSON="${CHECKPOINTS_DIR}/LATEST.json"
LATEST_MD="${CHECKPOINTS_DIR}/LATEST.md"
HISTORY_DIR="${CHECKPOINTS_DIR}/history"

if [[ ${PRINT_JSON_PATH} -eq 1 ]]; then
  echo "${LATEST_JSON}"
  exit 0
fi
if [[ ${PRINT_MD_PATH} -eq 1 ]]; then
  echo "${LATEST_MD}"
  exit 0
fi

if [[ ${HISTORY} -eq 1 ]]; then
  if [[ ! -d "${HISTORY_DIR}" ]]; then
    echo "No checkpoint history at ${HISTORY_DIR}" >&2
    exit 3
  fi
  # List oldest-to-newest so you can scroll forward in time
  find "${HISTORY_DIR}" -maxdepth 1 -type f -name '*.json' -print | sort
  exit 0
fi

if [[ ! -f "${LATEST_JSON}" ]]; then
  cat >&2 <<EOF
No checkpoint found at ${LATEST_JSON}.
Write one with:
  bash bootstrap/write-checkpoint.sh ${RESOLVED_TARGET} --agent <name> --phase '<what you are doing>' --next '<first next action>'
See _system/CHECKPOINT_PROTOCOL.md for the full API.
EOF
  exit 3
fi

case "${FORMAT}" in
  human) ;;
  md)
    if [[ ! -f "${LATEST_MD}" ]]; then
      echo "LATEST.md not present at ${LATEST_MD}" >&2
      exit 3
    fi
    cat "${LATEST_MD}"
    exit 0
    ;;
  json)
    cat "${LATEST_JSON}"
    exit 0
    ;;
  *)
    echo "Unknown --format ${FORMAT}. Expected: human, md, json." >&2
    exit 1
    ;;
esac

python3 - <<'PY' "${LATEST_JSON}" "${RESOLVED_TARGET}"
from __future__ import annotations

import json
import sys
from pathlib import Path

json_path = Path(sys.argv[1])
repo = Path(sys.argv[2])

try:
    record = json.loads(json_path.read_text())
except json.JSONDecodeError as exc:
    print(f"Checkpoint at {json_path} is not valid JSON: {exc}", file=sys.stderr)
    sys.exit(4)
except OSError as exc:
    print(f"Cannot read checkpoint at {json_path}: {exc}", file=sys.stderr)
    sys.exit(3)

def field(key: str, default=""):
    val = record.get(key, default)
    return val if val is not None else default

print("=" * 72)
print("AIAST RESUME BRIEFING")
print("=" * 72)
print(f"Checkpoint kind : {field('kind')}")
print(f"Created at      : {field('created_at')}")
print(f"Written by      : {field('agent') or 'unknown'}")
sid = field("session_id")
if sid:
    print(f"Session id      : {sid}")
print(f"Repo            : {field('repo')}")
print(f"Branch          : {field('branch')}")
print(f"Template version: {field('template_version')}")
print(f"Confidence      : {field('confidence')}")
print("")

def block(title: str, body: str) -> None:
    if not body:
        return
    print(f"-- {title} --")
    print(body)
    print("")

block("Phase", field("phase"))
block("Objective", field("objective"))

completed = record.get("completed_steps") or []
if completed:
    print("-- Completed this session --")
    for item in completed:
        print(f"  [x] {item}")
    print("")

block("In-progress step", field("in_progress_step"))

next_actions = record.get("next_actions") or []
if next_actions:
    print("-- Next actions (ordered) --")
    for i, item in enumerate(next_actions, start=1):
        print(f"  {i}. {item}")
    print("")

blockers = record.get("blockers") or []
if blockers:
    print("-- Blockers --")
    for item in blockers:
        print(f"  ! {item}")
    print("")

resume_files = record.get("resume_files") or []
if resume_files:
    print("-- Resume files (load these first) --")
    for item in resume_files:
        print(f"  - {item}")
    print("")

resume_command = field("resume_command")
if resume_command:
    print("-- Resume command --")
    print(f"  > {resume_command}")
    print("")

validation = record.get("validation_state") or {}
if any((validation.get(k) for k in ("last_command", "last_result", "last_run_at"))):
    print("-- Validation state at checkpoint --")
    if validation.get("last_command"):
        print(f"  command: {validation['last_command']}")
    if validation.get("last_result"):
        print(f"  result : {validation['last_result']}")
    if validation.get("last_run_at"):
        print(f"  run at : {validation['last_run_at']}")
    print("")

notes = record.get("notes") or []
if notes:
    print("-- Notes --")
    for item in notes:
        print(f"  - {item}")
    print("")

print("=" * 72)
print(
    "Paste or summarize this briefing at the top of your next turn, then"
    " follow the 'Next actions' list. If any resume file has drifted or the"
    " next action is no longer valid, write a fresh checkpoint with"
    " bootstrap/write-checkpoint.sh before continuing."
)
PY
