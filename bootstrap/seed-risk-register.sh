#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: seed-risk-register.sh <target-repo>
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
RISK_REGISTER="${TARGET_REPO}/RISK_REGISTER.md"

if [[ ! -f "${PROFILE}" ]]; then
  echo "Missing project profile: ${PROFILE}" >&2
  exit 1
fi

if [[ ! -f "${TEST_STRATEGY}" ]]; then
  echo "Missing test strategy file: ${TEST_STRATEGY}" >&2
  exit 1
fi

if [[ ! -f "${RISK_REGISTER}" ]]; then
  echo "Missing risk register file: ${RISK_REGISTER}" >&2
  exit 1
fi

python3 - <<'PY' "${PROFILE}" "${TEST_STRATEGY}" "${RISK_REGISTER}"
from pathlib import Path
import re
import sys

profile_path = Path(sys.argv[1])
test_strategy_path = Path(sys.argv[2])
risk_register_path = Path(sys.argv[3])

profile_text = profile_path.read_text()
test_strategy_text = test_strategy_path.read_text()
risk_text = risk_register_path.read_text()


def field(text: str, label: str) -> str:
    match = re.search(rf"^- {re.escape(label)}:[ \t]*(.*)$", text, re.MULTILINE)
    return match.group(1).strip() if match else ""


def clean_csv(value: str) -> list[str]:
    return [item.strip() for item in value.split(",") if item.strip()]


validation_gaps: list[str] = []
for label in (
    "format or lint",
    "typecheck",
    "unit tests",
    "integration tests",
    "end-to-end or smoke",
    "build or packaging checks",
    "security or policy checks",
):
    value = field(test_strategy_text, label)
    if (not value) or ("confirm manually" in value) or ("not yet established" in value):
        validation_gaps.append(label)

gap_summary = ", ".join(validation_gaps[:3]) if validation_gaps else "repo-local validation proof"
if len(validation_gaps) > 3:
    gap_summary = f"{gap_summary}, and additional inferred lanes"

packaging_surfaces = clean_csv(field(profile_text, "Packaging / deploy roots"))
packaging_summary = ", ".join(packaging_surfaces[:4]) if packaging_surfaces else "packaging, install, mobile, or AI scaffolds"

security_gaps = []
for label in (
    "Safety / compliance",
    "Security",
    "Secret handling",
    "Data classification",
    "Audit or retention requirements",
    "Threat model doc",
):
    if not field(profile_text, label):
        security_gaps.append(label.lower())

security_gap_summary = ", ".join(security_gaps[:3]) if security_gaps else "project-specific security posture"
if len(security_gaps) > 3:
    security_gap_summary = f"{security_gap_summary}, and related security fields"

active_risks = f"""- Risk: Validation baseline is still partially inferred or unproven
  Severity: Medium
  Area: validation / onboarding
  Why it matters: The repo-local confidence model still depends on confirming {gap_summary} against real commands instead of inference alone.
  Mitigation: Run the smallest real repo-local validation lane, replace fallback lines in `TEST_STRATEGY.md`, and record exact passing evidence in `_system/context/CURRENT_STATUS.md`.
  Trigger to revisit: After the first successful repo-local validation run, when toolchain assumptions change, or before any release-readiness claim.
  Owner: current maintainer or active agent

- Risk: Generated delivery surfaces may not match the repo's real packaging and install needs yet
  Severity: Medium
  Area: packaging / install
  Why it matters: {packaging_summary} are present or inferred, but they still need repo-local review and proof before any distribution or deployment claim is trustworthy.
  Mitigation: Review generated runtime surfaces, confirm packaging targets and installer commands in `_system/PROJECT_PROFILE.md`, and run the first relevant build, install, or smoke proof.
  Trigger to revisit: Before packaging work, before distribution, or after changing deployment targets.
  Owner: current maintainer or active agent

- Risk: Security and compliance posture is not yet repo-specific
  Severity: High
  Area: security / compliance
  Why it matters: The operating system can point to baseline checks, but {security_gap_summary} are still unset or too generic for confident release or exposure decisions.
  Mitigation: Fill the security and compliance section in `_system/PROJECT_PROFILE.md`, confirm secret-handling and data-classification rules, and keep `bootstrap/scan-security.sh` in the real validation path.
  Trigger to revisit: Before using real secrets, before external exposure, before production-like data handling, or before release readiness.
  Owner: current maintainer or active agent"""

watch_list = """- Replace or remove these seeded first-pass risks once repo-local validation evidence and project-specific profile truth exist.
- Add or tighten operational risk entries as soon as ports, background services, deployment topology, or release policy become concrete.
- **Template drift:** Downstream app repos may fall behind AIAST upgrades if `bootstrap/update-template.sh` (or equivalent) is not run on a cadence. *Severity: low for sandbox repos; higher for production.* Mitigation: track AIAST version in `_system/.template-version` and refresh from master template when security or validation contracts change."""

active_placeholder = "## Active risks\n\n- None recorded yet.\n\n## Watch list"
watch_placeholder = "## Watch list\n\n- None recorded yet.\n\n## Usage rules"

if active_placeholder in risk_text:
    risk_text = risk_text.replace(
        active_placeholder,
        f"## Active risks\n\n{active_risks}\n\n## Watch list",
        1,
    )

if watch_placeholder in risk_text:
    risk_text = risk_text.replace(
        watch_placeholder,
        f"## Watch list\n\n{watch_list}\n\n## Usage rules",
        1,
    )

risk_register_path.write_text(risk_text)
PY

echo "Seeded risk register for ${TARGET_REPO}"
