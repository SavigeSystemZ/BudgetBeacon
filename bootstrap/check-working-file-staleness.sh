#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: check-working-file-staleness.sh [target-repo] [--strict]

Detect potentially stale working files (WHERE_LEFT_OFF.md, TODO.md, PLAN.md,
RISK_REGISTER.md) by comparing git modification timestamps against the current
session activity and checking for internal consistency signals.

Exit codes:
  0  all working files appear current
  1  stale or inconsistent working files detected (strict mode)
  2  warnings detected but not blocking (non-strict mode)
EOF
}

TARGET_REPO=""
STRICT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict) STRICT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      if [[ -z "${TARGET_REPO}" ]]; then
        TARGET_REPO="$1"; shift
      else
        echo "Unexpected argument: $1" >&2; exit 1
      fi
      ;;
  esac
done

if [[ -z "${TARGET_REPO}" ]]; then
  TARGET_REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fi

if [[ ! -d "${TARGET_REPO}" ]]; then
  echo "Target repo does not exist: ${TARGET_REPO}" >&2
  exit 1
fi

python3 - <<'PY' "${TARGET_REPO}" "${STRICT}"
from __future__ import annotations

import re
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
strict = sys.argv[2] == "1"
warnings: list[str] = []

WORKING_FILES = [
    "WHERE_LEFT_OFF.md",
    "TODO.md",
    "PLAN.md",
    "FIXME.md",
    "RISK_REGISTER.md",
    "TEST_STRATEGY.md",
    "RELEASE_NOTES.md",
]

CONTEXT_FILES = [
    "_system/context/CURRENT_STATUS.md",
    "_system/context/DECISIONS.md",
]


def git_last_modified(path: Path) -> datetime | None:
    """Get the last git commit timestamp for a file."""
    try:
        result = subprocess.run(
            ["git", "log", "-1", "--format=%aI", "--", str(path)],
            cwd=repo,
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.returncode == 0 and result.stdout.strip():
            return datetime.fromisoformat(result.stdout.strip())
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    return None


def has_uncommitted_changes(path: Path) -> bool:
    """Check if a file has uncommitted changes."""
    rel = str(path.relative_to(repo))
    try:
        result = subprocess.run(
            ["git", "diff", "--name-only", "--", rel],
            cwd=repo,
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.stdout.strip():
            return True
        result = subprocess.run(
            ["git", "diff", "--cached", "--name-only", "--", rel],
            cwd=repo,
            capture_output=True,
            text=True,
            timeout=10,
        )
        return bool(result.stdout.strip())
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return False


def extract_timestamp(text: str) -> datetime | None:
    """Try to extract a date from common handoff patterns."""
    patterns = [
        r"Timestamp:\s*(\d{4}-\d{2}-\d{2})",
        r"Last updated:\s*(\d{4}-\d{2}-\d{2})",
        r"Date:\s*(\d{4}-\d{2}-\d{2})",
        r"\((\d{4}-\d{2}-\d{2})\)",
    ]
    for pat in patterns:
        match = re.search(pat, text)
        if match:
            try:
                return datetime.fromisoformat(match.group(1) + "T00:00:00+00:00")
            except ValueError:
                continue
    return None


now = datetime.now(timezone.utc)
staleness_threshold = timedelta(days=14)

# Check each working file
for rel in WORKING_FILES + CONTEXT_FILES:
    path = repo / rel
    if not path.is_file():
        continue

    text = path.read_text()

    # Skip template-default files (not yet filled in)
    if "not set yet" in text and rel == "WHERE_LEFT_OFF.md":
        continue

    # If the file has pending local edits, treat it as actively maintained
    # even when the last commit is old.
    if has_uncommitted_changes(path):
        continue

    # Check git modification age
    last_mod = git_last_modified(path)
    if last_mod and (now - last_mod) > staleness_threshold:
        age_days = (now - last_mod).days
        warnings.append(
            f"{rel}: last git commit was {age_days} days ago — may be stale"
        )

    # Check for internal timestamp freshness
    embedded_ts = extract_timestamp(text)
    if embedded_ts and (now - embedded_ts) > staleness_threshold:
        age_days = (now - embedded_ts).days
        warnings.append(
            f"{rel}: embedded timestamp is {age_days} days old"
        )

# Cross-check WHERE_LEFT_OFF.md vs TODO.md phase consistency
wlo_path = repo / "WHERE_LEFT_OFF.md"
todo_path = repo / "TODO.md"
plan_path = repo / "PLAN.md"

if wlo_path.is_file() and plan_path.is_file():
    wlo_text = wlo_path.read_text()
    plan_text = plan_path.read_text()

    # Extract phase from WHERE_LEFT_OFF
    wlo_phase = re.search(r"Current phase:\s*(.+)", wlo_text)
    plan_obj = re.search(r"Current target outcome:\s*(.+)", plan_text)
    if not plan_obj:
        plan_obj = re.search(r"Objective[^:]*:\s*(.+)", plan_text)

    if wlo_phase and plan_obj:
        wlo_phase_text = wlo_phase.group(1).strip().lower()
        plan_obj_text = plan_obj.group(1).strip().lower()
        # Very loose check: if they share no significant words, flag it
        wlo_words = set(re.findall(r"\w{4,}", wlo_phase_text))
        plan_words = set(re.findall(r"\w{4,}", plan_obj_text))
        if wlo_words and plan_words and not wlo_words & plan_words:
            warnings.append(
                "WHERE_LEFT_OFF.md phase and PLAN.md objective share no common terms — may be misaligned"
            )

# Check for WHERE_LEFT_OFF.md completeness
if wlo_path.is_file():
    wlo_text = wlo_path.read_text()
    required_sections = [
        ("Session Snapshot", r"##\s*Session Snapshot"),
        ("Last Completed Work", r"##\s*Last Completed Work"),
        ("Validation Run", r"##\s*Validation Run"),
        ("Next Best Step", r"##\s*Next Best Step"),
        ("Handoff Packet", r"##\s*Handoff Packet"),
    ]
    for label, pattern in required_sections:
        if not re.search(pattern, wlo_text):
            warnings.append(
                f"WHERE_LEFT_OFF.md is missing required section: {label}"
            )

    # Check that validation run has actual content
    val_match = re.search(
        r"##\s*Validation Run\s*\n(.*?)(?=\n##|\Z)", wlo_text, re.DOTALL
    )
    if val_match:
        val_content = val_match.group(1).strip()
        if not val_content or val_content.startswith("- Command:\n- Result:\n"):
            warnings.append(
                "WHERE_LEFT_OFF.md Validation Run section has no recorded evidence"
            )

# Check TODO.md for items without priority signals
if todo_path.is_file():
    todo_text = todo_path.read_text()
    unchecked = re.findall(r"^- \[ \] (.+)$", todo_text, re.MULTILINE)
    no_priority = [
        item
        for item in unchecked
        if not re.match(r"(CRITICAL|HIGH|MEDIUM|LOW):", item)
        and "not set" not in item.lower()
        and "fill in" not in item.lower()
        and "replace" not in item.lower()
    ]
    # Only warn if there are many unprioritized items (fresh repos get a pass)
    if len(no_priority) > 5:
        warnings.append(
            f"TODO.md has {len(no_priority)} items without priority signals "
            f"(CRITICAL/HIGH/MEDIUM/LOW)"
        )

if warnings:
    print("working_file_staleness_detected")
    for w in warnings:
        print(f"  - {w}")
    raise SystemExit(1 if strict else 2)

print("working_files_current")
PY
