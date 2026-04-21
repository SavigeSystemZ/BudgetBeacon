#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: seed-product-brief.sh <target-repo> [--app-name NAME]
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
PRODUCT_BRIEF="${TARGET_REPO}/PRODUCT_BRIEF.md"

if [[ ! -f "${PROFILE}" ]]; then
  echo "Missing project profile: ${PROFILE}" >&2
  exit 1
fi

if [[ ! -f "${PRODUCT_BRIEF}" ]]; then
  echo "Missing product brief file: ${PRODUCT_BRIEF}" >&2
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

python3 - <<'PY' "${PROFILE}" "${PRODUCT_BRIEF}" "${APP_NAME}"
from pathlib import Path
import re
import sys

profile_path = Path(sys.argv[1])
product_brief_path = Path(sys.argv[2])
app_name = sys.argv[3]

profile_text = profile_path.read_text()
brief_text = product_brief_path.read_text()


def field(label: str) -> str:
    match = re.search(rf"^- {re.escape(label)}:[ \t]*(.*)$", profile_text, re.MULTILINE)
    return match.group(1).strip() if match else ""


def replace_label(text: str, label: str, value: str) -> str:
    pattern = rf"^- {re.escape(label)}:.*$"
    return re.sub(pattern, f"- {label}: {value}", text, count=1, flags=re.MULTILINE)


def ensure_build_shape_fields(text: str) -> str:
    labels = [
        "Recommended starter blueprint",
        "Recommendation confidence",
        "Recommendation rationale",
        "Selected starter blueprint",
        "Why this blueprint fits",
        "Planned repo shape",
        "First milestone",
        "Initial validation focus",
        "Next decision gates",
    ]
    missing = [label for label in labels if not re.search(rf"^- {re.escape(label)}:", text, re.MULTILINE)]
    if not missing:
        return text
    anchor = "## Build shape\n\n"
    if anchor not in text:
        return text
    insertion = "".join(f"- {label}:\n" for label in missing)
    return text.replace(anchor, anchor + insertion, 1)


brief_text = ensure_build_shape_fields(brief_text)


seeded = {
    "Product name": app_name,
    "Product category": field("Product category") or "set once the product shape is specific enough to exclude lookalikes",
    "One-line summary": field("Repo purpose") or "define the app promise in one clear sentence before major implementation begins",
    "Why it should exist": "capture the user pain, operator leverage, or market opportunity this app resolves",
    "Primary users": field("Primary users") or "name the real people or operators who should benefit first",
    "Primary workflows": field("Main workflows") or "list the core flows the first milestone must prove",
    "Success indicators": field("Primary success criteria") or "record the measurable signal that shows the app is genuinely useful",
    "Non-goals": field("Non-goals") or "state what this repo should not try to solve in the first phase",
    "Visual direction": field("Visual quality bar") or "deliberate, differentiated, and product-specific rather than template-generic",
    "Interaction bar": field("Interaction quality bar") or "fast, clear, low-friction flows with designed states from the first milestone",
    "Performance bar": field("Performance quality bar") or "snappy enough that the first slice feels trustworthy under normal use",
    "Reliability bar": "clear degraded states, explicit error handling, and no fake capability claims",
    "Trust and safety bar": "security-conscious defaults, honest validation claims, and explicit handling of risky actions",
    "Recommended starter blueprint": "manual review required",
    "Recommendation confidence": "low",
    "Recommendation rationale": "review the persisted recommendation, then explicitly choose the blueprint that matches the intended product shape",
    "Selected starter blueprint": "not yet selected",
    "Why this blueprint fits": "choose a starter blueprint after the product frame and delivery surfaces are clearer",
    "Planned repo shape": "decide after selecting a starter blueprint",
    "First milestone": "prove one end-to-end user-facing or operator-facing slice with real validation",
    "Initial validation focus": "confirm one real build, launch, test, or smoke path early and keep it passing",
    "Next decision gates": "starter blueprint, persistence model, deployment targets, packaging expectations, and AI scope",
}

for label, value in seeded.items():
    brief_text = replace_label(brief_text, label, value)

product_brief_path.write_text(brief_text)
PY

echo "Seeded product brief for ${APP_NAME}"
