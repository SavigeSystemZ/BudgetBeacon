#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: seed-working-state.sh <target-repo> [--app-name NAME]
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

TARGET_REPO=""
APP_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-name)
      APP_NAME="${2:-}"
      shift 2
      ;;
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
  usage
  exit 1
fi

PROFILE="${TARGET_REPO}/_system/PROJECT_PROFILE.md"

if [[ ! -f "${PROFILE}" ]]; then
  echo "Missing project profile: ${PROFILE}" >&2
  exit 1
fi

if [[ -z "${APP_NAME}" ]]; then
  APP_NAME="$(python3 - <<'PY' "${PROFILE}"
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text()
match = re.search(r"^- App name:[ \t]*(.+)$", text, re.MULTILINE)
print(match.group(1).strip() if match else "")
PY
)"
fi

if [[ -z "${APP_NAME}" ]]; then
  APP_NAME="$(basename -- "${TARGET_REPO}")"
fi

python3 - <<'PY' "${TARGET_REPO}" "${APP_NAME}"
from pathlib import Path
from datetime import datetime, timezone
import sys

root = Path(sys.argv[1])
app_name = sys.argv[2]
timestamp = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

updates = {
    root / "TODO.md": {
        "- [ ] HIGH: Define the repo's next concrete outcome": f"- [ ] HIGH: Establish the first validated baseline for {app_name}",
        "- [ ] HIGH: Turn `PRODUCT_BRIEF.md` into repo-specific truth": (
            f"- [ ] HIGH: Refine `PRODUCT_BRIEF.md` for {app_name} so the product frame and first build shape are explicit"
        ),
        "- [ ] HIGH: Review the recommended starter blueprint and explicitly apply it if the repo is still greenfield": (
            "- [ ] HIGH: Review the recommended starter blueprint and explicitly apply it if the repo is still greenfield"
        ),
        "- [ ] MEDIUM: Replace remaining neutral prompts with repo-specific truth after install": (
            f"- [ ] MEDIUM: Finish onboarding and confirm the first working validation path for {app_name}"
        ),
        "- [ ] LOW: Keep working files current as the repo evolves": (
            "- [ ] MEDIUM: Begin the first product or platform milestone once onboarding is complete"
        ),
        "- [ ] MEDIUM: Record initial risks in `RISK_REGISTER.md`": (
            "- [ ] MEDIUM: Review and refine the seeded first-pass risks in `RISK_REGISTER.md`"
        ),
        "- [ ] MEDIUM: Record the repo's real validation lane in `TEST_STRATEGY.md`": (
            "- [ ] MEDIUM: Record the repo's real validation lane in `TEST_STRATEGY.md` after the first successful repo-local check"
        ),
    },
    root / "PLAN.md": {
        "- Current target outcome: set this to the active repo milestone": f"- Current target outcome: Establish a clean, validated baseline for {app_name}",
        "- Why it matters now: record why this work matters to the repo, user, or release": "- Why it matters now: The repo needs a truthful operating picture before deeper feature work begins.",
        "- Deadline or forcing function: record if one exists": "- Deadline or forcing function: Complete onboarding before the first substantial implementation pass.",
        "- User or operator outcome:": "- User or operator outcome: A new agent can enter the repo and immediately see how to build, validate, and continue safely.",
        "- Technical outcome:": "- Technical outcome: Runtime boundaries, validation commands, and current repo structure are documented and verified.",
        "- Design or product-quality outcome:": "- Design or product-quality outcome: The first visible surface should already reflect intentional design and best-practice structure.",
        "- In scope:": "- In scope: profile completion, validation mapping, first smoke check, and working-state initialization.",
        "- Out of scope:": "- Out of scope: broad product expansion before the baseline is proven.",
        "- Dependencies:": "- Dependencies: repo inspection, `PRODUCT_BRIEF.md`, available toolchain, and at least one real validation command.",
        "- Known unknowns:": "- Known unknowns: framework-specific gaps, deployment assumptions, and missing environment details.",
        "- Commands to run:": "- Commands to run: start with the smallest real build, test, or smoke command for the repo.",
        "- Evidence to capture:": "- Evidence to capture: the first passing validation result and any unresolved onboarding gaps.",
        "- Stop conditions:": "- Stop conditions: missing runtime path understanding, failing baseline validation, or hidden environment blockers.",
        "- Release-blocking checks:": "- Release-blocking checks: baseline validation must be explicit before any release claim exists.",
        "- Risks that could invalidate the plan:": "- Risks that could invalidate the plan: incorrect framework assumptions, hidden dependencies, or stale repo docs.",
        "- Fallback path if the plan fails:": "- Fallback path if the plan fails: reduce scope, document the blocker, and stabilize the repo state before proceeding.",
        "- Define what \"done\" means for this repo milestone.": "- Define what \"done\" means for this repo milestone: the repo profile is meaningfully filled, the first validation path is proven, and the next milestone is explicit.",
    },
    root / "WHERE_LEFT_OFF.md": {
        "- Current phase: not set yet": "- Current phase: Onboarding",
        "- Working branch or lane: `main`": "- Working branch or lane: `main`",
        "- Completion status: not started — fill after first meaningful work session": "- Completion status: System installed, repo-specific truth still being established",
        "- Resume confidence: low — no prior session recorded": "- Resume confidence: medium",
        "Record the most recent meaningful work here. Be concrete:": f"Installed the local AI operating system for {app_name} and seeded the first working surfaces.",
    },
    root / "_system/context/CURRENT_STATUS.md": {
        "- Active branch or lane:": "- Active branch or lane: main or current default branch",
        "- Current milestone:": "- Current milestone: Baseline onboarding",
        "- Current primary objective:": f"- Current primary objective: Turn {app_name} into a fully understood, validated repo before larger changes land.",
        "- Current plan file or phase:": "- Current plan file or phase: PLAN.md - onboarding baseline",
        "- Current release target:": "- Current release target: internal baseline",
        "- Latest known passing validation:": "- Latest known passing validation: not yet established",
        "- Latest known failing validation:": "- Latest known failing validation: none recorded yet",
        "- Current confidence level:": "- Current confidence level: Partial until repo-specific validation is confirmed",
        "- Last updated:": f"- Last updated: {timestamp}",
        "- Updated by:": "- Updated by: bootstrap/seed-working-state.sh",
    },
    root / "RELEASE_NOTES.md": {
        "- Target label:": "- Target label: baseline-onboarding",
        "- Intended audience:": "- Intended audience: internal engineering and agent operators",
        "- Release goal:": "- Release goal: confirm the repo-local AI operating system is installed cleanly and the first validation path is understood",
        "- Release confidence:": "- Release confidence: not ready until onboarding validation is complete",
    },
}

def replace_exact_line(text: str, old_line: str, new_line: str) -> str:
    old_with_newline = f"{old_line}\n"
    new_with_newline = f"{new_line}\n"
    if old_with_newline in text:
        return text.replace(old_with_newline, new_with_newline, 1)
    if text.endswith(old_line):
        return text[: -len(old_line)] + new_line
    return text


for path, replacements in updates.items():
    text = path.read_text()
    for old, new in replacements.items():
        text = replace_exact_line(text, old, new)
    if path.name == "TODO.md":
        text = replace_exact_line(
            text,
            "- [ ] Select and apply a starter blueprint if the repo is still greenfield",
            "- [ ] Review the recommended starter blueprint and explicitly apply it if the repo is still greenfield",
        )
    path.write_text(text)

where_left_off = root / "WHERE_LEFT_OFF.md"
text = where_left_off.read_text()
text = replace_exact_line(text, "- Timestamp:", f"- Timestamp: {timestamp}")
where_left_off.write_text(text)
PY

echo "Seeded working state for ${APP_NAME}"
