#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage: validate-instruction-layer.sh [target-repo] [--validator-root <template-root>]

Validate the host-safe instruction-layer surfaces and generated operating profile.
EOF
}

TARGET_REPO=""
VALIDATOR_ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --validator-root)
      VALIDATOR_ROOT="${2:-}"
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
  TARGET_REPO="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
fi

if [[ ! -d "${TARGET_REPO}" ]]; then
  echo "Target repo does not exist: ${TARGET_REPO}" >&2
  exit 1
fi

if [[ -z "${VALIDATOR_ROOT}" ]]; then
  VALIDATOR_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
else
  VALIDATOR_ROOT="$(cd -- "${VALIDATOR_ROOT}" && pwd)"
fi

if [[ ! -d "${VALIDATOR_ROOT}" ]]; then
  echo "Validator root does not exist: ${VALIDATOR_ROOT}" >&2
  exit 1
fi

run_validation_step() {
  local label="$1"
  shift
  local output
  if output="$("$@" 2>&1)"; then
    return 0
  fi
  printf 'instruction_layer_validation_failed: %s\n' "${label}" >&2
  if [[ -n "${output}" ]]; then
    printf '%s\n' "${output}" >&2
  fi
  exit 1
}

for rel in \
  "bootstrap/generate-host-adapters.sh" \
  "bootstrap/generate-operating-profile.sh" \
  "bootstrap/detect-instruction-conflicts.sh" \
  "bootstrap/check-host-adapter-alignment.sh" \
  "bootstrap/check-host-ingestion.sh" \
  "bootstrap/check-host-bundle.sh"; do
  if [[ ! -f "${VALIDATOR_ROOT}/${rel}" ]]; then
    echo "Validator root is missing required validation script: ${rel}" >&2
    exit 1
  fi
done

required_files=(
  "_system/INSTRUCTION_PRECEDENCE_CONTRACT.md"
  "_system/instruction-precedence.json"
  "_system/HOST_ADAPTER_POLICY.md"
  "_system/HOST_BUNDLE_CONTRACT.md"
  "_system/READ_BUNDLES.md"
  "_system/TEMPLATE_CHANGE_IMPACT_POLICY.md"
  "_system/SELF_HEALING_BOUNDARY.md"
  "_system/VERSION_SENSITIVE_RESEARCH_PROTOCOL.md"
  "_system/WORKSPACE_AUTHORITY_AND_CONTAINMENT_PROTOCOL.md"
  "_system/PROJECT_IDENTITY_AND_SCOPE_PROTOCOL.md"
  "_system/INSTRUCTION_DOMAIN_ALIGNMENT_PROTOCOL.md"
  "_system/PROJECT_DOMAIN_MANIFEST.json"
  "_system/PROJECT_DOMAIN_MANIFEST.template.json"
  "_system/schemas/project-domain-manifest.schema.json"
  "bootstrap/check-instruction-domain-alignment.sh"
  "_system/GLOBAL_REDIRECT_SHIM_POLICY.md"
  "_system/SCAVENGE_AND_DISCOVERY_AUTHORIZATION.md"
  "_system/SESSION_ENVIRONMENT_REPORT_CONTRACT.md"
  "_system/ORPHAN_META_SNAPSHOT_POLICY.md"
  "_system/host-adapter-manifest.json"
  "_system/INSTRUCTION_CONFLICT_PLAYBOOK.md"
  "_system/REPO_OPERATING_PROFILE.md"
  "_system/repo-operating-profile.json"
  "_system/PROMPT_EMISSION_CONTRACT.md"
  "_system/PROMPTS_INDEX.md"
  "_system/aiaast-capabilities.json"
  "bootstrap/generate-host-adapters.sh"
  "bootstrap/check-host-adapter-alignment.sh"
  "bootstrap/emit-host-prompt.sh"
  "bootstrap/check-host-ingestion.sh"
  "bootstrap/emit-host-bundle.sh"
  "bootstrap/check-host-bundle.sh"
  "bootstrap/check-working-directory-alignment.sh"
  "bootstrap/check-project-target-consistency.sh"
  "bootstrap/check-global-shim-alignment.sh"
  "bootstrap/emit-session-environment.sh"
  "bootstrap/snapshot-meta-to-orphan-branch.sh"
  "bootstrap/detect-instruction-conflicts.sh"
  "bootstrap/generate-operating-profile.sh"
  "bootstrap/validate-instruction-layer.sh"
)

for rel in "${required_files[@]}"; do
  if [[ ! -f "${TARGET_REPO}/${rel}" ]]; then
    echo "Missing required instruction-layer file: ${rel}" >&2
    exit 1
  fi
done

jq -e . "${TARGET_REPO}/_system/host-adapter-manifest.json" >/dev/null 2>&1 || { echo "Invalid JSON: _system/host-adapter-manifest.json" >&2; exit 1; }
jq -e . "${TARGET_REPO}/_system/instruction-precedence.json" >/dev/null 2>&1 || { echo "Invalid JSON: _system/instruction-precedence.json" >&2; exit 1; }
jq -e . "${TARGET_REPO}/_system/repo-operating-profile.json" >/dev/null 2>&1 || { echo "Invalid JSON: _system/repo-operating-profile.json" >&2; exit 1; }
jq -e . "${TARGET_REPO}/_system/aiaast-capabilities.json" >/dev/null 2>&1 || { echo "Invalid JSON: _system/aiaast-capabilities.json" >&2; exit 1; }
jq -e '.read_bundles_contract_path and (.preferred_bundle_ids | arrays) and .change_impact_policy_path and .self_healing_boundary_path and .version_sensitive_research_protocol_path' "${TARGET_REPO}/_system/repo-operating-profile.json" >/dev/null 2>&1 || { echo "repo-operating-profile.json is missing required governance fields" >&2; exit 1; }

run_validation_step "generate-host-adapters --check" bash "${VALIDATOR_ROOT}/bootstrap/generate-host-adapters.sh" "${TARGET_REPO}" --check
run_validation_step "generate-operating-profile --check" bash "${VALIDATOR_ROOT}/bootstrap/generate-operating-profile.sh" "${TARGET_REPO}" --check
run_validation_step "detect-instruction-conflicts --strict" bash "${VALIDATOR_ROOT}/bootstrap/detect-instruction-conflicts.sh" "${TARGET_REPO}" --strict
run_validation_step "check-host-adapter-alignment" bash "${VALIDATOR_ROOT}/bootstrap/check-host-adapter-alignment.sh" "${TARGET_REPO}" --validator-root "${VALIDATOR_ROOT}"
run_validation_step "check-host-ingestion" bash "${VALIDATOR_ROOT}/bootstrap/check-host-ingestion.sh" "${TARGET_REPO}"
run_validation_step "check-host-bundle" bash "${VALIDATOR_ROOT}/bootstrap/check-host-bundle.sh" "${TARGET_REPO}" --validator-root "${VALIDATOR_ROOT}"

python3 - <<'PY' "${TARGET_REPO}"
from __future__ import annotations

import sys
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
issues: list[str] = []

required_mentions = {
    repo / "AGENTS.md": ["_system/INSTRUCTION_PRECEDENCE_CONTRACT.md", "_system/REPO_OPERATING_PROFILE.md", "_system/READ_BUNDLES.md", "_system/TEMPLATE_CHANGE_IMPACT_POLICY.md", "_system/SELF_HEALING_BOUNDARY.md", "_system/VERSION_SENSITIVE_RESEARCH_PROTOCOL.md", "_system/INSTRUCTION_DOMAIN_ALIGNMENT_PROTOCOL.md"],
    repo / "_system" / "CONTEXT_INDEX.md": ["INSTRUCTION_PRECEDENCE_CONTRACT.md", "REPO_OPERATING_PROFILE.md", "PROMPT_EMISSION_CONTRACT.md", "HOST_BUNDLE_CONTRACT.md", "READ_BUNDLES.md", "TEMPLATE_CHANGE_IMPACT_POLICY.md", "SELF_HEALING_BOUNDARY.md", "VERSION_SENSITIVE_RESEARCH_PROTOCOL.md", "WORKSPACE_AUTHORITY_AND_CONTAINMENT_PROTOCOL.md", "PROJECT_IDENTITY_AND_SCOPE_PROTOCOL.md", "INSTRUCTION_DOMAIN_ALIGNMENT_PROTOCOL.md", "PROJECT_DOMAIN_MANIFEST.json", "GLOBAL_REDIRECT_SHIM_POLICY.md", "SCAVENGE_AND_DISCOVERY_AUTHORIZATION.md", "SESSION_ENVIRONMENT_REPORT_CONTRACT.md", "ORPHAN_META_SNAPSHOT_POLICY.md"],
    repo / "_system" / "LOAD_ORDER.md": ["_system/INSTRUCTION_PRECEDENCE_CONTRACT.md", "_system/REPO_OPERATING_PROFILE.md", "_system/READ_BUNDLES.md", "INSTRUCTION_DOMAIN_ALIGNMENT_PROTOCOL.md"],
    repo / "_system" / "AGENT_DISCOVERY_MATRIX.md": ["_system/HOST_ADAPTER_POLICY.md", "bootstrap/generate-host-adapters.sh", "bootstrap/check-host-adapter-alignment.sh", "_system/READ_BUNDLES.md", "_system/TEMPLATE_CHANGE_IMPACT_POLICY.md", "_system/SELF_HEALING_BOUNDARY.md", "_system/VERSION_SENSITIVE_RESEARCH_PROTOCOL.md"],
    repo / "_system" / "MASTER_SYSTEM_PROMPT.md": ["_system/INSTRUCTION_PRECEDENCE_CONTRACT.md", "_system/REPO_OPERATING_PROFILE.md", "INSTRUCTION_DOMAIN_ALIGNMENT_PROTOCOL.md"],
    repo / "_system" / "PROJECT_RULES.md": ["_system/INSTRUCTION_PRECEDENCE_CONTRACT.md"],
    repo / "_system" / "TEMPLATE_NEUTRALITY_POLICY.md": ["PROMPT_EMISSION_CONTRACT.md"],
    repo / "_system" / "HOST_ADAPTER_POLICY.md": ["host-adapter-manifest.json", "generate-host-adapters.sh", "check-host-adapter-alignment.sh"],
    repo / "_system" / "HOST_BUNDLE_CONTRACT.md": ["PROMPT_EMISSION_CONTRACT.md", "emit-host-bundle.sh", "check-host-bundle.sh", "_system/READ_BUNDLES.md"],
    repo / "_system" / "PROMPTS_INDEX.md": ["_system/PROMPT_EMISSION_CONTRACT.md", "_system/HOST_BUNDLE_CONTRACT.md", "bootstrap/emit-host-prompt.sh", "bootstrap/emit-host-bundle.sh", "bootstrap/check-host-bundle.sh"],
    repo / "bootstrap" / "README.md": ["detect-instruction-conflicts.sh", "generate-host-adapters.sh", "check-host-adapter-alignment.sh", "generate-operating-profile.sh", "validate-instruction-layer.sh", "emit-host-prompt.sh", "check-host-ingestion.sh", "emit-host-bundle.sh", "check-host-bundle.sh", "check-instruction-domain-alignment.sh", "INSTALLER_AND_UPGRADE_CONTRACT.md", "_system/READ_BUNDLES.md", "_system/TEMPLATE_CHANGE_IMPACT_POLICY.md", "_system/SELF_HEALING_BOUNDARY.md", "_system/VERSION_SENSITIVE_RESEARCH_PROTOCOL.md"],
}

for path, expected in required_mentions.items():
    if not path.exists():
        issues.append(f"Missing required doc for instruction-layer mention check: {path.relative_to(repo)}")
        continue
    text = path.read_text()
    for item in expected:
        if item not in text:
            issues.append(f"{path.relative_to(repo)} is missing required mention: {item}")

forbidden_markers = [
    "Savige Systems",
    "The Savage Architect",
    "Michael Todd Spaulding",
]

scan_roots = [
    repo / "AGENTS.md",
    repo / "CODEX.md",
    repo / "CLAUDE.md",
    repo / "GEMINI.md",
    repo / "WINDSURF.md",
    repo / ".cursorrules",
    repo / ".windsurfrules",
    repo / ".github",
    repo / "_system",
    repo / "bootstrap",
]

for root in scan_roots:
    if not root.exists():
        continue
    targets = [root] if root.is_file() else [path for path in root.rglob("*") if path.is_file()]
    for path in targets:
        if path == repo / "bootstrap" / "validate-instruction-layer.sh":
            continue
        try:
            text = path.read_text()
        except UnicodeDecodeError:
            continue
        for marker in forbidden_markers:
            if marker in text:
                issues.append(f"Forbidden template-specific content leaked into instruction surfaces: {marker} [{path.relative_to(repo)}]")

if issues:
    print("instruction_layer_validation_failed")
    for item in issues:
        print(f"- {item}")
    raise SystemExit(1)

print("instruction_layer_ok")
PY
