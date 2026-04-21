#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: check-hallucination.sh [target-repo]

Heuristically detect ungrounded confidence and claim-evidence mismatches in core working files.
EOF
}

TARGET_REPO=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
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
  TARGET_REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fi

if [[ ! -d "${TARGET_REPO}" ]]; then
  echo "Target repo does not exist: ${TARGET_REPO}" >&2
  exit 1
fi

python3 - <<'PY' "${TARGET_REPO}"
from __future__ import annotations

import re
import sys
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
issues: list[str] = []

def read(rel: str) -> str:
    path = repo / rel
    return path.read_text() if path.exists() else ""

def get_field(text: str, label: str) -> str:
    match = re.search(rf"^- {re.escape(label)}:\s*(.*)$", text, re.MULTILINE)
    return match.group(1).strip() if match else ""

current_status = read("_system/context/CURRENT_STATUS.md")
where_left_off = read("WHERE_LEFT_OFF.md")
release_notes = read("RELEASE_NOTES.md")
change_log = read("CHANGELOG.md")

latest_passing = get_field(current_status, "Latest known passing validation")
latest_failing = get_field(current_status, "Latest known failing validation")
current_confidence = get_field(current_status, "Current confidence level").lower()
resume_confidence = get_field(where_left_off, "Resume confidence").lower()
completion_status = get_field(where_left_off, "Completion status").lower()
release_confidence = get_field(release_notes, "Release confidence").lower()
validation_command = get_field(where_left_off, "Command")
validation_result = get_field(where_left_off, "Result")

emptyish = {"", "unknown", "not yet established", "none", "n/a"}

def is_positive_confidence(value: str) -> bool:
    lowered = value.lower()
    if not lowered:
        return False
    if any(token in lowered for token in ("not ", "partial", "medium", "low", "unknown", "degraded")):
        return False
    return any(token in lowered for token in ("high", "ready", "green", "strong", "complete", "production"))

if is_positive_confidence(current_confidence) and latest_passing.lower() in emptyish:
    issues.append("CURRENT_STATUS claims high confidence without a recorded latest passing validation.")

if is_positive_confidence(release_confidence) and latest_passing.lower() in emptyish:
    issues.append("RELEASE_NOTES claims high release confidence without recorded passing validation evidence.")

if any(word in resume_confidence for word in ("high", "very high")) and (not validation_command or not validation_result):
    issues.append("WHERE_LEFT_OFF claims high resume confidence without a completed Validation Run section.")

if "partial" in completion_status and any(word in resume_confidence for word in ("high", "very high")):
    issues.append("WHERE_LEFT_OFF says work is partial but resume confidence is high.")

if validation_result.lower() in {"pass", "passed", "green", "successful", "success"} and latest_passing.lower() in emptyish:
    issues.append("WHERE_LEFT_OFF records successful validation but CURRENT_STATUS has no latest passing validation.")

suspicious_patterns = [
    (change_log, "CHANGELOG.md"),
    (release_notes, "RELEASE_NOTES.md"),
    (where_left_off, "WHERE_LEFT_OFF.md"),
]

phrase_re = re.compile(
    r"\b(all tests pass|fully verified|production-ready|works end-to-end|complete and validated|release ready)\b",
    re.IGNORECASE,
)

for text, label in suspicious_patterns:
    for line in text.splitlines():
        if phrase_re.search(line) and latest_passing.lower() in emptyish:
            issues.append(f"{label} contains high-confidence claim without CURRENT_STATUS evidence: {line.strip()}")

if issues:
    print("hallucination_risk_detected")
    for item in issues:
        print(f"- {item}")
    sys.exit(1)

print("hallucination_risk_low")
PY
