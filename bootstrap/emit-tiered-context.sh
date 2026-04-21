#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: emit-tiered-context.sh <target-repo> [--tier A|B|C|D] [--model <model-name>] [--list]

Emit a context load sequence appropriate for the given tier or model.

Options:
  --tier    Explicit tier (A=Full, B=Standard, C=Compact, D=Minimal)
  --model   Model name to look up tier from context-budget-profiles.json
  --list    List all files in the selected tier without reading them
EOF
}

TARGET=""
TIER=""
MODEL=""
LIST_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tier) TIER="${2:-}"; shift 2 ;;
    --model) MODEL="${2:-}"; shift 2 ;;
    --list) LIST_ONLY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      if [[ -z "${TARGET}" ]]; then
        TARGET="$1"; shift
      else
        echo "Unexpected argument: $1" >&2; exit 1
      fi
      ;;
  esac
done

if [[ -z "${TARGET}" ]]; then
  usage
  exit 1
fi

python3 - <<'PY' "${TARGET}" "${TIER}" "${MODEL}" "${LIST_ONLY}"
from __future__ import annotations

import json
import sys
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
tier_arg = sys.argv[2].strip().upper()
model_arg = sys.argv[3].strip().lower()
list_only = sys.argv[4] == "1"

profiles_path = repo / "_system" / "context-budget-profiles.json"
if not profiles_path.is_file():
    print("Missing context-budget-profiles.json", file=sys.stderr)
    raise SystemExit(1)

data = json.loads(profiles_path.read_text())
profiles = data.get("profiles", {})

# Resolve tier
tier = tier_arg
if not tier and model_arg:
    for key, val in profiles.items():
        if key.lower() == model_arg:
            tier = val["tier"]
            break
    if not tier:
        # Fuzzy match
        for key, val in profiles.items():
            if model_arg in key.lower():
                tier = val["tier"]
                break
if not tier:
    tier = "A"  # Default to full

# Define file lists per tier
TIER_D = [
    "AGENTS.md",
    "_system/PROJECT_PROFILE.md",
    "WHERE_LEFT_OFF.md",
]

TIER_C = TIER_D + [
    "_system/INSTRUCTION_PRECEDENCE_CONTRACT.md",
    "_system/MASTER_SYSTEM_PROMPT.md",
    "_system/PROJECT_RULES.md",
    "TODO.md",
    "FIXME.md",
    "PLAN.md",
    "PRODUCT_BRIEF.md",
]

TIER_B = TIER_C + [
    "_system/REPO_OPERATING_PROFILE.md",
    "_system/CONTEXT_INDEX.md",
    "_system/LOAD_ORDER.md",
    "_system/WORKING_FILES_GUIDE.md",
    "_system/TEMPLATE_NEUTRALITY_POLICY.md",
    "_system/EXECUTION_PROTOCOL.md",
    "_system/MULTI_AGENT_COORDINATION.md",
    "_system/SUB_AGENT_HOST_DELEGATION.md",
    "_system/AGENT_ROLE_CATALOG.md",
    "_system/AGENT_DISCOVERY_MATRIX.md",
    "_system/VALIDATION_GATES.md",
    "_system/SYSTEM_AWARENESS_PROTOCOL.md",
    "_system/HALLUCINATION_DEFENSE_PROTOCOL.md",
    "ROADMAP.md",
    "DESIGN_NOTES.md",
    "ARCHITECTURE_NOTES.md",
    "TEST_STRATEGY.md",
    "CHANGELOG.md",
]

TIER_A = TIER_B + [
    "RESEARCH_NOTES.md",
    "RISK_REGISTER.md",
    "RELEASE_NOTES.md",
    "_system/KEY.md",
    "_system/MCP_CONFIG.md",
    "_system/CODING_STANDARDS.md",
    "_system/PERFORMANCE_BUDGET.md",
    "_system/ACCESSIBILITY_STANDARDS.md",
    "_system/API_DESIGN_STANDARDS.md",
    "_system/DEPENDENCY_GOVERNANCE.md",
    "_system/MODERN_UI_PATTERNS.md",
    "_system/AUTH_AND_ONBOARDING_PATTERNS.md",
    "_system/DESIGN_EXCELLENCE_FRAMEWORK.md",
    "_system/SECURITY_REDACTION_AND_AUDIT.md",
    "_system/SECURITY_HARDENING_CONTRACT.md",
    "_system/OBSERVABILITY_STANDARDS.md",
    "_system/CHECKPOINT_PROTOCOL.md",
    "_system/DEBUG_REPAIR_PLAYBOOK.md",
    "_system/RELEASE_READINESS_PROTOCOL.md",
    "_system/FAILURE_MODES_AND_RECOVERY.md",
    "_system/PLUGIN_CONTRACT.md",
    "_system/PROMPTS_INDEX.md",
    "_system/PROMPT_EMISSION_CONTRACT.md",
    "_system/CONTEXT_BUDGET_STRATEGY.md",
]

tiers = {"A": TIER_A, "B": TIER_B, "C": TIER_C, "D": TIER_D}
files = tiers.get(tier, TIER_A)

tier_defs = data.get("tier_definitions", {})
label = tier_defs.get(tier, {}).get("label", tier)

print(f"# Context tier: {tier} ({label}) — {len(files)} files")

for f in files:
    path = repo / f
    if list_only:
        exists = "ok" if path.is_file() else "MISSING"
        print(f"  [{exists}] {f}")
    else:
        print(f)

if not list_only:
    print(f"\ncontext_tier_emitted: {tier} files={len(files)}")
PY
