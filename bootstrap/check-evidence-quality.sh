#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: check-evidence-quality.sh [target-repo] [--strict]

Scan WHERE_LEFT_OFF.md and _system/context/CURRENT_STATUS.md for grounded
evidence: validation commands with results, concrete file lists, and specific
next steps. Flags ungrounded claims that could mislead the next agent.

Exit codes:
  0  evidence quality acceptable
  1  evidence quality issues detected (strict mode)
  2  warnings detected (non-strict mode)
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
import sys
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
strict = sys.argv[2] == "1"
warnings: list[str] = []

# Ungrounded claim patterns — phrases that suggest a result without evidence
UNGROUNDED_PATTERNS = [
    (r"\ball tests pass\b", "Claim 'all tests pass' without command/count evidence"),
    (r"\bbuild succeeds?\b", "Claim 'build succeeds' without command evidence"),
    (r"\bfully (tested|validated|verified)\b", "Claim 'fully tested/validated' without scope"),
    (r"\bno (issues|problems|errors)\b", "Claim 'no issues' without validation evidence"),
    (r"\beverything (works|passes|is green)\b", "Vague 'everything works' claim"),
    (r"\bshould (work|be fine|pass)\b", "Speculative 'should work' instead of evidence"),
]

# Evidence indicators — signs that a claim is grounded
EVIDENCE_INDICATORS = [
    r"→\s*(system_ok|pass|ok|success)",
    r"exit\s*(code\s*)?0",
    r"\d+\s*(tests?|specs?)\s*(pass|green)",
    r"command:",
    r"result:",
    r"`[^`]+`\s*→",
    r"output:",
]


def check_file(rel: str, path: Path) -> None:
    if not path.is_file():
        return
    text = path.read_text()

    # Skip template-default files
    if "not set yet" in text:
        return

    for pattern, message in UNGROUNDED_PATTERNS:
        matches = list(re.finditer(pattern, text, re.IGNORECASE))
        for match in matches:
            # Check surrounding context (±3 lines) for evidence indicators
            start = max(0, text.rfind("\n", 0, match.start() - 200))
            end = min(len(text), text.find("\n", match.end() + 200))
            context = text[start:end] if end > start else text
            has_evidence = any(
                re.search(ep, context, re.IGNORECASE) for ep in EVIDENCE_INDICATORS
            )
            if not has_evidence:
                line_num = text[:match.start()].count("\n") + 1
                warnings.append(f"{rel}:{line_num}: {message}")


check_file("WHERE_LEFT_OFF.md", repo / "WHERE_LEFT_OFF.md")
check_file(
    "_system/context/CURRENT_STATUS.md",
    repo / "_system" / "context" / "CURRENT_STATUS.md",
)
check_file("RELEASE_NOTES.md", repo / "RELEASE_NOTES.md")
check_file("TEST_STRATEGY.md", repo / "TEST_STRATEGY.md")

# Check that WHERE_LEFT_OFF.md has a non-empty Handoff Packet
wlo = repo / "WHERE_LEFT_OFF.md"
if wlo.is_file():
    wlo_text = wlo.read_text()
    if "not set yet" not in wlo_text:
        packet_match = re.search(
            r"##\s*Handoff Packet\s*\n(.*?)(?=\n##|\Z)", wlo_text, re.DOTALL
        )
        if packet_match:
            packet = packet_match.group(1).strip()
            # Check required packet fields have content
            required_fields = [
                ("Agent:", "Handoff Packet is missing Agent"),
                ("Timestamp:", "Handoff Packet is missing Timestamp"),
                ("Objective:", "Handoff Packet is missing Objective"),
                ("Next best step:", "Handoff Packet is missing Next best step"),
            ]
            for field, msg in required_fields:
                field_match = re.search(
                    rf"^-\s*\*?\*?{re.escape(field)}\*?\*?\s*(.*)$",
                    packet,
                    re.MULTILINE,
                )
                if not field_match or not field_match.group(1).strip():
                    warnings.append(f"WHERE_LEFT_OFF.md: {msg}")

if warnings:
    print("evidence_quality_issues")
    for w in warnings:
        print(f"  - {w}")
    raise SystemExit(1 if strict else 2)

print("evidence_quality_ok")
PY
