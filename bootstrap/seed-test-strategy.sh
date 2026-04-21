#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: seed-test-strategy.sh <target-repo>
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

TARGET_REPO="$1"

if [[ ! -d "${TARGET_REPO}" ]]; then
  echo "Target repo does not exist: ${TARGET_REPO}" >&2
  exit 1
fi

PROFILE="${TARGET_REPO}/_system/PROJECT_PROFILE.md"
TEST_STRATEGY="${TARGET_REPO}/TEST_STRATEGY.md"

if [[ ! -f "${PROFILE}" ]]; then
  echo "Missing project profile: ${PROFILE}" >&2
  exit 1
fi

if [[ ! -f "${TEST_STRATEGY}" ]]; then
  echo "Missing test strategy file: ${TEST_STRATEGY}" >&2
  exit 1
fi

python3 - <<'PY' "${PROFILE}" "${TEST_STRATEGY}"
from pathlib import Path
import re
import sys

profile_path = Path(sys.argv[1])
test_strategy_path = Path(sys.argv[2])

profile_text = profile_path.read_text()
test_text = test_strategy_path.read_text()


def field(label: str) -> str:
    match = re.search(rf"^- {re.escape(label)}:[ \t]*(.*)$", profile_text, re.MULTILINE)
    return match.group(1).strip() if match else ""


def join_values(*values: str) -> str:
    seen: list[str] = []
    for value in values:
        if value and value not in seen:
            seen.append(value)
    return " | ".join(seen)


def lane_or_default(*labels: str, fallback: str) -> str:
    values = [field(label) for label in labels]
    combined = join_values(*values)
    return combined if combined else fallback


def replace_exact_line(text: str, old_line: str, new_line: str) -> str:
    old_with_newline = f"{old_line}\n"
    new_with_newline = f"{new_line}\n"
    if old_with_newline in text:
        return text.replace(old_with_newline, new_with_newline, 1)
    if text.endswith(old_line):
        return text[: -len(old_line)] + new_line
    return text


seeded_lines = {
    "- required confidence for local changes:": "- required confidence for local changes: run the smallest impacted validation lane plus any touched bootstrap or system checks",
    "- required confidence for risky changes:": "- required confidence for risky changes: run unit, integration, and any relevant smoke, build, packaging, or security lanes before handoff",
    "- required confidence for release candidates:": "- required confidence for release candidates: run every defined lane in this file and record exact outcomes in release-facing notes or handoff",
    "- format or lint:": f"- format or lint: {lane_or_default('Format', 'Lint', fallback='no format or lint command inferred yet; confirm manually')}",
    "- typecheck:": f"- typecheck: {lane_or_default('Typecheck', fallback='no typecheck command inferred yet; confirm manually')}",
    "- unit tests:": f"- unit tests: {lane_or_default('Unit tests', fallback='no unit-test command inferred yet; confirm manually')}",
    "- integration tests:": f"- integration tests: {lane_or_default('Integration tests', fallback='no integration-test command inferred yet; confirm manually')}",
    "- end-to-end or smoke:": f"- end-to-end or smoke: {lane_or_default('End-to-end or smoke', fallback='no smoke command inferred yet; confirm manually')}",
    "- build or packaging checks:": f"- build or packaging checks: {lane_or_default('Build', 'Install / launch verification', 'Packaging verification', fallback='no build or packaging command inferred yet; confirm manually')}",
    "- security or policy checks:": f"- security or policy checks: {lane_or_default('Security or policy checks', fallback='no security or policy command inferred yet; confirm manually')}",
    "- critical flows that must be proven:": "- critical flows that must be proven: primary user flow, startup or install path, and any high-risk surface touched by the change",
    "- areas allowed to rely on lighter validation:": "- areas allowed to rely on lighter validation: docs, prompt wording, and low-risk content-only changes after targeted checks",
    "- expected evidence for high-risk changes:": "- expected evidence for high-risk changes: exact commands run, pass or fail outcomes, notable warnings, and any skipped lanes with reasons",
    "- None recorded yet.": "- Confirm the seeded validation lanes against the first real repo-local run and record any missing coverage explicitly.",
}

for old_line, new_line in seeded_lines.items():
    test_text = replace_exact_line(test_text, old_line, new_line)

test_strategy_path.write_text(test_text)
PY

echo "Seeded test strategy for ${TARGET_REPO}"
