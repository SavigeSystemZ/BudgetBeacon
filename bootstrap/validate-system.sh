#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: validate-system.sh <target-repo-or-template> [--strict] [--mode auto|template|installed] [--validator-root <template-root>]
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

TARGET=""
STRICT=0
MODE="auto"
VALIDATOR_ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict)
      STRICT=1
      shift
      ;;
    --validator-root)
      VALIDATOR_ROOT="${2:-}"
      shift 2
      ;;
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "${TARGET}" ]]; then
        TARGET="$1"
        shift
      else
        echo "Unexpected argument: $1" >&2
        exit 1
      fi
      ;;
  esac
done

require_file() {
  local rel="$1"
  if [[ ! -f "${TARGET}/${rel}" ]]; then
    echo "Missing required file: ${rel}" >&2
    exit 1
  fi
}

require_files() {
  local rel
  for rel in "$@"; do
    require_file "${rel}"
  done
}

if [[ ! -d "${TARGET}" ]]; then
  echo "Target does not exist: ${TARGET}" >&2
  exit 1
fi

if [[ -z "${VALIDATOR_ROOT}" ]]; then
  VALIDATOR_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
else
  VALIDATOR_ROOT="$(cd -- "${VALIDATOR_ROOT}" && pwd)"
fi

for rel in "bootstrap/validate-instruction-layer.sh" "bootstrap/check-system-awareness.sh"; do
  if [[ ! -f "${VALIDATOR_ROOT}/${rel}" ]]; then
    echo "Validator root is missing required validation script: ${rel}" >&2
    exit 1
  fi
done

REPO_MODE="$(aiaast_resolve_repo_mode "${TARGET}" "${MODE}")"

require_files \
  ".installable-product-root" \
  "AGENTS.md" \
  "CLAUDE.md" \
  "GEMINI.md" \
  "CODEX.md" \
  "WINDSURF.md" \
  ".cursorrules" \
  ".windsurfrules" \
  ".github/copilot-instructions.md" \
  "DEEPSEEK.md" \
  ".aider.conf.yml" \
  ".continuerules" \
  ".clinerules" \
  "PEARAI.md" \
  "LOCAL_MODELS.md" \
  "AIAST_VERSION.md" \
  "AIAST_CHANGELOG.md" \
  "TODO.md" \
  "FIXME.md" \
  "WHERE_LEFT_OFF.md" \
  "CHANGELOG.md" \
  "PLAN.md" \
  "PRODUCT_BRIEF.md" \
  "ROADMAP.md" \
  "DESIGN_NOTES.md" \
  "ARCHITECTURE_NOTES.md" \
  "RESEARCH_NOTES.md" \
  "TEST_STRATEGY.md" \
  "RISK_REGISTER.md" \
  "RELEASE_NOTES.md" \
  "notes/README.md" \
  "docs/README.md" \
  "_system/.template-version" \
  "_system/.template-install.json" \
  "_system/PROJECT_PROFILE.md" \
  "_system/INSTRUCTION_DOMAIN_ALIGNMENT_PROTOCOL.md" \
  "_system/PROJECT_DOMAIN_MANIFEST.json" \
  "_system/PROJECT_DOMAIN_MANIFEST.template.json" \
  "_system/schemas/project-domain-manifest.schema.json" \
  "_system/INSTRUCTION_PRECEDENCE_CONTRACT.md" \
  "_system/REPO_OPERATING_PROFILE.md" \
  "_system/CONTEXT_INDEX.md" \
  "_system/SYSTEM_ORCHESTRATION_GUIDE.md" \
  "_system/KEY.md" \
  "_system/LOAD_ORDER.md" \
  "_system/READ_BUNDLES.md" \
  "_system/HOST_ADAPTER_POLICY.md" \
  "_system/HOST_BUNDLE_CONTRACT.md" \
  "_system/host-adapter-manifest.json" \
  "_system/GOLDEN_EXAMPLES_POLICY.md" \
  "_system/SYSTEM_AWARENESS_PROTOCOL.md" \
  "_system/HALLUCINATION_DEFENSE_PROTOCOL.md" \
  "_system/SYSTEM_REGISTRY.json" \
  "_system/instruction-precedence.json" \
  "_system/repo-operating-profile.json" \
  "_system/WORKING_FILES_GUIDE.md" \
  "_system/TEMPLATE_NEUTRALITY_POLICY.md" \
  "_system/INTEGRITY_MANIFEST.sha256" \
  "_system/MASTER_SYSTEM_PROMPT.md" \
  "_system/PROJECT_RULES.md" \
  "_system/MEMORY_RULES.md" \
  "_system/EXECUTION_PROTOCOL.md" \
  "_system/TEMPLATE_CHANGE_IMPACT_POLICY.md" \
  "_system/SELF_HEALING_BOUNDARY.md" \
  "_system/VERSION_SENSITIVE_RESEARCH_PROTOCOL.md" \
  "_system/MULTI_AGENT_COORDINATION.md" \
  "_system/AGENT_ROLE_CATALOG.md" \
  "_system/CHECKPOINT_PROTOCOL.md" \
  "_system/AGENT_DISCOVERY_MATRIX.md" \
  "_system/VALIDATION_GATES.md" \
  "_system/DEBUG_REPAIR_PLAYBOOK.md" \
  "_system/PROVENANCE_AND_EVIDENCE.md" \
  "_system/REPO_BOUNDARY_AND_BACKUP.md" \
  "_system/MCP_CONFIG.md" \
  "_system/SECURITY_REDACTION_AND_AUDIT.md" \
  "_system/SECURITY_HARDENING_CONTRACT.md" \
  "_system/INSTALLATION_GUIDE.md" \
  "_system/PACKAGING_GUIDE.md" \
  "_system/MOBILE_GUIDE.md" \
  "_system/CHATBOT_GUIDE.md" \
  "_system/llm_config.yaml.example" \
  "_system/DESIGN_EXCELLENCE_FRAMEWORK.md" \
  "_system/RELEASE_READINESS_PROTOCOL.md" \
  "_system/FAILURE_MODES_AND_RECOVERY.md" \
  "_system/SYSTEM_EVOLUTION_POLICY.md" \
  "_system/STANDARDS_CONFLICT_RESOLUTION.md" \
  "_system/UPGRADE_AND_DRIFT_POLICY.md" \
  "_system/DOWNSTREAM_PRESERVATION_AND_SYNC_NOTICE_POLICY.md" \
  "_system/TEMPLATE_SYNC_NOTICE.md" \
  "_system/INSTALLER_AND_UPGRADE_CONTRACT.md" \
  "_system/CODING_STANDARDS.md" \
  "_system/PERFORMANCE_BUDGET.md" \
  "_system/ACCESSIBILITY_STANDARDS.md" \
  "_system/API_DESIGN_STANDARDS.md" \
  "_system/DEPENDENCY_GOVERNANCE.md" \
  "_system/MODERN_UI_PATTERNS.md" \
  "_system/AUTH_AND_ONBOARDING_PATTERNS.md" \
  "_system/OBSERVABILITY_STANDARDS.md" \
  "_system/THREAT_MODEL_TEMPLATE.md" \
  "_system/PLUGIN_CONTRACT.md" \
  "_system/CONTEXT_BUDGET_STRATEGY.md" \
  "_system/context-budget-profiles.json" \
  "_system/ENVIRONMENT_VALIDATION_CONTRACT.md" \
  "_system/health-history.json" \
  "_system/AGENT_PERFORMANCE_GUIDE.md" \
  "_system/agent-performance-profiles.json" \
  "_system/PROMPT_EFFECTIVENESS_TRACKING.md" \
  "_system/PROMPT_SYSTEM_BUILD_STANDARD.md" \
  "_system/PROMPT_SECURITY_BASELINE.md" \
  "_system/PROMPT_BACKEND_POLICY.md" \
  "_system/PROMPT_DOCKER_NETWORK_POLICY.md" \
  "_system/ports/PORT_POLICY.md" \
  "_system/ports/default_port_matrix.yaml" \
  "_system/ports/templates/README.md" \
  "_system/ports/templates/compose-loopback-snippet.yml" \
  "_system/design-system/THEME_GOVERNANCE.md" \
  "_system/context/prompt-usage-log.json" \
  "_system/QUICKSTART.md" \
  "_system/ARCHITECTURE_DIAGRAM.md" \
  "_system/TROUBLESHOOTING.md" \
  "_system/MIGRATION_GUIDE.md" \
  "_system/PROMPTS_INDEX.md" \
  "_system/PROMPT_EMISSION_CONTRACT.md" \
  "_system/SKILLS_INDEX.md" \
  "_system/INSTRUCTION_CONFLICT_PLAYBOOK.md" \
  "_system/CURSOR_AND_MULTI_HOST.md" \
  "_system/aiaast-capabilities.json" \
  "_system/README.md" \
  "_system/golden-examples/README.md" \
  "_system/golden-examples/PATTERN_INDEX.md" \
  "_system/golden-examples/golden-example-manifest.json" \
  "_system/golden-examples/patterns/CONTINUITY_AND_HANDOFF.md" \
  "_system/golden-examples/patterns/GOVERNANCE_AND_PROMPTING.md" \
  "_system/golden-examples/patterns/MULTI_AGENT_AND_MCP.md" \
  "_system/golden-examples/patterns/VALIDATION_AND_RELEASE.md" \
  "_system/golden-examples/patterns/PLATFORM_SURFACES.md" \
  "_system/golden-examples/patterns/MICROSERVICES_ARCHITECTURE.md" \
  "_system/golden-examples/patterns/EVENT_DRIVEN_AND_CQRS.md" \
  "_system/golden-examples/patterns/SERVERLESS_AND_EDGE.md" \
  "_system/golden-examples/patterns/REALTIME_COLLABORATION.md" \
  "_system/golden-examples/patterns/DATA_PIPELINE_AND_ML.md" \
  "_system/golden-examples/patterns/ERROR_HANDLING_PATTERNS.md" \
  "_system/golden-examples/patterns/TESTING_PATTERNS.md" \
  "_system/golden-examples/patterns/CODE_SNIPPET_EXAMPLES.md" \
  "_system/golden-examples/working-files/PROJECT_PROFILE_EXAMPLE.md" \
  "_system/golden-examples/working-files/PLAN_EXAMPLE.md" \
  "_system/golden-examples/working-files/WHERE_LEFT_OFF_EXAMPLE.md" \
  "_system/starter-blueprints/README.md" \
  "_system/starter-blueprints/REACT_VITE_TYPESCRIPT.md" \
  "_system/starter-blueprints/FASTAPI_API.md" \
  "_system/starter-blueprints/STATIC_FRONTEND.md" \
  "_system/starter-blueprints/NEXT_JS_FULLSTACK.md" \
  "_system/starter-blueprints/PYTHON_CLI_TOOL.md" \
  "_system/starter-blueprints/RUST_CLI_TOOL.md" \
  "_system/starter-blueprints/GO_SERVICE.md" \
  "_system/starter-blueprints/GRAPHQL_API.md" \
  "_system/starter-blueprints/GRPC_SERVICE.md" \
  "_system/starter-blueprints/BACKGROUND_WORKER.md" \
  "_system/starter-blueprints/DATABASE_MIGRATIONS.md" \
  "_system/starter-blueprints/TAURI_DESKTOP.md" \
  "_system/starter-blueprints/FLUTTER_ANDROID_CLIENT.md" \
  "_system/starter-blueprints/UNIVERSAL_APP_PLATFORM.md" \
  "_system/context/README.md" \
  "_system/context/CURRENT_STATUS.md" \
  "_system/context/DECISIONS.md" \
  "_system/context/MEMORY.md" \
  "_system/context/ARCHITECTURAL_INVARIANTS.md" \
  "_system/context/ASSUMPTIONS.md" \
  "_system/context/INTEGRATION_SURFACES.md" \
  "_system/context/OPEN_QUESTIONS.md" \
  "_system/context/QUALITY_DEBT.md" \
  "_system/mcp/README.md" \
  "_system/mcp/MCP_SERVER_CATALOG.md" \
  "_system/mcp/MCP_SERVER_CATALOG_TEMPLATE.md" \
  "_system/mcp/MCP_SELECTION_POLICY.md" \
  "_system/mcp/MCP_FAILURE_FALLBACKS.md" \
  "_system/ci/README.md" \
  "_system/ci/github-actions/ci.yml.example" \
  "_system/ci/github-actions/release.yml.example" \
  "_system/ci/github-actions/linux-packaging.yml.example" \
  "_system/ci/github-actions/android.yml.example" \
  "_system/ci/gitlab-ci.yml.example" \
  "_system/packaging/README.md" \
  "_system/packaging/python-packaging.md" \
  "_system/packaging/node-and-desktop-packaging.md" \
  "_system/packaging/rust-and-go-packaging.md" \
  "_system/packaging/templates/appimage.yml.example" \
  "_system/packaging/templates/flatpak-manifest.json.example" \
  "_system/packaging/templates/appimage-builder.yml.example" \
  "_system/packaging/templates/snapcraft.yaml.example" \
  "_system/packaging/templates/flatpak.yaml.example" \
  "_system/plugins/README.md" \
  "_system/plugins/security-scan/plugin.json" \
  "_system/plugins/security-scan/README.md" \
  "_system/plugins/security-scan/run.sh" \
  "_system/plugins/ci-integration/plugin.json" \
  "_system/plugins/ci-integration/README.md" \
  "_system/plugins/ci-integration/run.sh" \
  "_system/plugins/observability-setup/plugin.json" \
  "_system/plugins/observability-setup/README.md" \
  "_system/plugins/observability-setup/run.sh" \
  "_system/systemd/README.md" \
  "_system/systemd/http-service.example.service" \
  "_system/systemd/worker.example.service" \
  "_system/systemd/scheduled-task.example.service" \
  "_system/systemd/scheduled-task.example.timer" \
  "bootstrap/init-project.sh" \
  "bootstrap/install-missing-files.sh" \
  "bootstrap/update-template.sh" \
  "bootstrap/validate-system.sh" \
  "bootstrap/validate-mcp-health.sh" \
  "bootstrap/validate-instruction-layer.sh" \
  "bootstrap/verify-integrity.sh" \
  "bootstrap/generate-system-key.sh" \
  "bootstrap/generate-system-registry.sh" \
  "bootstrap/generate-operating-profile.sh" \
  "bootstrap/generate-host-adapters.sh" \
  "bootstrap/detect-instruction-conflicts.sh" \
  "bootstrap/check-repo-permissions.sh" \
  "bootstrap/check-system-awareness.sh" \
  "bootstrap/check-hallucination.sh" \
  "bootstrap/check-install-boundary.sh" \
  "bootstrap/check-delivery-gate-alignment.sh" \
  "bootstrap/check-host-adapter-alignment.sh" \
  "bootstrap/system-doctor.sh" \
  "bootstrap/heal-system.sh" \
  "bootstrap/repair-system.sh" \
  "bootstrap/uninstall-system.sh" \
  "bootstrap/detect-drift.sh" \
  "bootstrap/configure-project-profile.sh" \
  "bootstrap/suggest-project-profile.sh" \
  "bootstrap/seed-product-brief.sh" \
  "bootstrap/recommend-starter-blueprint.sh" \
  "bootstrap/apply-starter-blueprint.sh" \
  "bootstrap/seed-risk-register.sh" \
  "bootstrap/seed-test-strategy.sh" \
  "bootstrap/seed-working-state.sh" \
  "bootstrap/print-agent-map.sh" \
  "bootstrap/check-placeholders.sh" \
  "bootstrap/check-agent-orchestration.sh" \
  "bootstrap/check-packaging-targets.sh" \
  "bootstrap/check-host-ingestion.sh" \
  "bootstrap/check-host-bundle.sh" \
  "bootstrap/check-runtime-foundations.sh" \
  "bootstrap/scan-security.sh" \
  "bootstrap/validate-plugin.sh" \
  "bootstrap/discover-plugins.sh" \
  "bootstrap/emit-tiered-context.sh" \
  "bootstrap/compress-context-file.sh" \
  "bootstrap/emit-auxiliary-brief.sh" \
  "bootstrap/check-environment.sh" \
  "bootstrap/generate-diagnostic-report.sh" \
  "bootstrap/report-health-trends.sh" \
  "bootstrap/run-sast.sh" \
  "bootstrap/check-supply-chain.sh" \
  "bootstrap/scan-container.sh" \
  "bootstrap/check-network-bindings.sh" \
  "bootstrap/wizard.sh" \
  "bootstrap/upgrade-assistant.sh" \
  "bootstrap/track-semantic-changes.sh" \
  "bootstrap/emit-host-prompt.sh" \
  "bootstrap/emit-host-bundle.sh" \
  "bootstrap/generate-systemd-unit.sh" \
  "bootstrap/generate-runtime-foundations.sh" \
  "bootstrap/templates/runtime/LICENSE" \
  "bootstrap/templates/runtime/NOTICE" \
  "bootstrap/templates/runtime/.credits-hidden" \
  "bootstrap/templates/runtime/packaging/README.md" \
  "bootstrap/templates/runtime/packaging/__AIAST_DESKTOP_ID__.desktop" \
  "bootstrap/templates/runtime/packaging/appimage.yml" \
  "bootstrap/templates/runtime/packaging/flatpak-manifest.json" \
  "bootstrap/templates/runtime/packaging/snapcraft.yaml" \
  "bootstrap/templates/runtime/packaging/signing/README.md" \
  "bootstrap/templates/runtime/distribution/README.md" \
  "bootstrap/templates/runtime/distribution/platforms/linux/README.md" \
  "bootstrap/templates/runtime/distribution/platforms/windows/README.md" \
  "bootstrap/templates/runtime/distribution/platforms/windows/Install.ps1" \
  "bootstrap/templates/runtime/distribution/platforms/macos/README.md" \
  "bootstrap/templates/runtime/distribution/platforms/android/README.md" \
  "bootstrap/templates/runtime/distribution/platforms/ios/README.md" \
  "bootstrap/templates/runtime/ops/install/README.md" \
  "bootstrap/templates/runtime/ops/install/install.sh" \
  "bootstrap/templates/runtime/ops/install/uninstall.sh" \
  "bootstrap/templates/runtime/ops/install/repair.sh" \
  "bootstrap/templates/runtime/ops/install/purge.sh" \
  "bootstrap/templates/runtime/ops/install/lib/runtime-foundation.sh" \
  "bootstrap/templates/runtime/ops/install/lib/port_allocator.py" \
  "bootstrap/templates/runtime/ops/env/.env.example" \
  "bootstrap/templates/runtime/ops/compose/compose.yml" \
  "bootstrap/templates/runtime/ops/logging/README.md" \
  "bootstrap/templates/runtime/docs/security/architecture.md" \
  "bootstrap/templates/runtime/docs/security/backend-inventory.md" \
  "bootstrap/templates/runtime/docs/security/validation.md" \
  "bootstrap/templates/runtime/docs/security/rollback.md" \
  "bootstrap/templates/runtime/registry/ports.yaml" \
  "bootstrap/templates/runtime/registry/port_governance.yaml" \
  "bootstrap/templates/runtime/registry/port_assignments.yaml" \
  "bootstrap/templates/runtime/registry/backend-assignments.yaml" \
  "bootstrap/templates/runtime/tools/security-preflight.sh" \
  "bootstrap/templates/runtime/tools/port_registry_lib.py" \
  "bootstrap/templates/runtime/tools/check-port-collisions.py" \
  "bootstrap/templates/runtime/tools/preflight_port_scan.py" \
  "bootstrap/templates/runtime/mobile/README.md" \
  "bootstrap/templates/runtime/mobile/flutter/README.md" \
  "bootstrap/templates/runtime/mobile/flutter/pubspec.yaml" \
  "bootstrap/templates/runtime/mobile/flutter/lib/main.dart" \
  "bootstrap/templates/runtime/mobile/flutter/android/app/src/main/AndroidManifest.xml" \
  "bootstrap/templates/runtime/ai/README.md" \
  "bootstrap/templates/runtime/ai/llm_config.yaml" \
  "bootstrap/templates/runtime/ai/chatbot-intents.md" \
  "bootstrap/scaffold-system.sh" \
  "bootstrap/README.md" \
  "bootstrap/lib/aiaast-lib.sh"

if [[ ! -f "${TARGET}/README.md" && ! -f "${TARGET}/AI_SYSTEM_README.md" ]]; then
  echo "Missing required system overview: README.md or AI_SYSTEM_README.md" >&2
  exit 1
fi

require_files \
  "_system/prompt-templates/system_prompt_template.md" \
  "_system/prompt-templates/developer_prompt_template.md" \
  "_system/prompt-templates/user_prompt_template.md" \
  "_system/prompt-templates/architecture_prompt_template.md" \
  "_system/prompt-templates/repair_prompt_template.md" \
  "_system/prompt-templates/review_prompt_template.md" \
  "_system/prompt-templates/optimization_prompt_template.md" \
  "_system/prompt-packs/M0_FOUNDATION.md" \
  "_system/prompt-packs/M1_FEATURE_DELIVERY.md" \
  "_system/prompt-packs/M2_DEBUG_AND_STABILIZE.md" \
  "_system/prompt-packs/M3_REVIEW_AND_RELEASE.md" \
  "_system/prompt-packs/M4_ARCHITECTURE_EXPANSION.md" \
  "_system/prompt-packs/M5_MIGRATION_AND_REFACTOR.md" \
  "_system/prompt-packs/M6_INSTALL_AND_DISTRIBUTION.md" \
  "_system/prompt-packs/M7_DESIGN_EXCELLENCE.md" \
  "_system/prompt-packs/M8_SECURITY_AND_COMPLIANCE.md" \
  "_system/prompt-packs/M9_MULTI_AGENT_CONTINUITY.md" \
  "_system/prompt-packs/M10_GREENFIELD_BOOTSTRAP.md" \
  "_system/prompt-packs/M11_MATURE_REPO_RETROFIT.md" \
  "_system/prompt-packs/M12_PERFORMANCE_OPTIMIZATION.md" \
  "_system/prompt-packs/M13_ACCESSIBILITY_AND_INCLUSION.md" \
  "_system/prompt-packs/M14_SECURITY_HARDENING.md" \
  "_system/review-playbooks/ARCHITECTURE_REVIEW_PLAYBOOK.md" \
  "_system/review-playbooks/UI_UX_REVIEW_PLAYBOOK.md" \
  "_system/review-playbooks/PERFORMANCE_REVIEW_PLAYBOOK.md" \
  "_system/review-playbooks/SECURITY_REVIEW_PLAYBOOK.md" \
  "_system/review-playbooks/SECURITY_HARDENING_REVIEW_PLAYBOOK.md" \
  "_system/review-playbooks/ACCESSIBILITY_REVIEW_PLAYBOOK.md" \
  "_system/review-playbooks/DEPENDENCY_REVIEW_PLAYBOOK.md" \
  "_system/review-playbooks/CODE_QUALITY_REVIEW_PLAYBOOK.md" \
  ".cursor/mcp.json" \
  ".cursor/README.md" \
  ".cursor/commands/accessibility-review.md" \
  ".cursor/commands/architecture-review.md" \
  ".cursor/commands/checkpoint.md" \
  ".cursor/commands/code-quality-review.md" \
  ".cursor/commands/code-review.md" \
  ".cursor/commands/composer-session.md" \
  ".cursor/commands/compress-context.md" \
  ".cursor/commands/debug.md" \
  ".cursor/commands/dependency-review.md" \
  ".cursor/commands/design-review.md" \
  ".cursor/commands/load-context.md" \
  ".cursor/commands/concise-session.md" \
  ".cursor/commands/performance-review.md" \
  ".cursor/commands/release-readiness.md" \
  ".cursor/commands/session-start.md" \
  ".cursor/commands/verify.md" \
  ".cursor/rules/00-context-load.mdc" \
  ".cursor/rules/10-project-boundaries.mdc" \
  ".cursor/rules/20-multi-agent-awareness.mdc" \
  ".cursor/rules/30-validation-gate.mdc" \
  ".cursor/rules/40-mcp-and-tooling.mdc" \
  ".cursor/rules/50-working-files.mdc" \
  ".cursor/rules/IDE_HOST_CURSOR_WINDSURF.mdc" \
  ".cursor/rules/60-composer-orchestration.mdc" \
  ".cursor/skills/accessibility-review/SKILL.md" \
  ".cursor/skills/architecture-review/SKILL.md" \
  ".cursor/skills/checkpoint-handoff/SKILL.md" \
  ".cursor/skills/code-quality-review/SKILL.md" \
  ".cursor/skills/code-review/SKILL.md" \
  ".cursor/skills/debug-playbook/SKILL.md" \
  ".cursor/skills/dependency-review/SKILL.md" \
  ".cursor/skills/design-review/SKILL.md" \
  ".cursor/skills/load-context/SKILL.md" \
  ".cursor/skills/concise-communication/SKILL.md" \
  ".cursor/skills/compress-context-input/SKILL.md" \
  ".cursor/skills/mcp-config/SKILL.md" \
  ".cursor/skills/performance-review/SKILL.md" \
  ".cursor/skills/prompt-pack-generator/SKILL.md" \
  ".cursor/skills/release-readiness/SKILL.md" \
  ".cursor/skills/verify-gate/SKILL.md" \
  ".cursor/agents/README.md" \
  ".cursor/agents/architecture.md" \
  ".cursor/agents/context-curator.md" \
  ".cursor/agents/design-reviewer.md" \
  ".cursor/agents/implementation-worker.md" \
  ".cursor/agents/orchestrator.md" \
  ".cursor/agents/release-manager.md" \
  ".cursor/agents/security-reviewer.md" \
  ".cursor/agents/validator.md" \
  ".cursor/agents/composer-lead.md"

jq -e . "${TARGET}/.cursor/mcp.json" >/dev/null 2>&1 || { echo "Invalid JSON: .cursor/mcp.json" >&2; exit 1; }
jq -e . "${TARGET}/_system/mcp/servers.cursor.example.json" >/dev/null 2>&1 || { echo "Invalid JSON: _system/mcp/servers.cursor.example.json" >&2; exit 1; }
jq -e . "${TARGET}/_system/.template-install.json" >/dev/null 2>&1 || { echo "Invalid JSON: _system/.template-install.json" >&2; exit 1; }
jq -e . "${TARGET}/_system/SYSTEM_REGISTRY.json" >/dev/null 2>&1 || { echo "Invalid JSON: _system/SYSTEM_REGISTRY.json" >&2; exit 1; }
jq -e . "${TARGET}/_system/instruction-precedence.json" >/dev/null 2>&1 || { echo "Invalid JSON: _system/instruction-precedence.json" >&2; exit 1; }
jq -e . "${TARGET}/_system/host-adapter-manifest.json" >/dev/null 2>&1 || { echo "Invalid JSON: _system/host-adapter-manifest.json" >&2; exit 1; }
jq -e . "${TARGET}/_system/repo-operating-profile.json" >/dev/null 2>&1 || { echo "Invalid JSON: _system/repo-operating-profile.json" >&2; exit 1; }
jq -e . "${TARGET}/_system/aiaast-capabilities.json" >/dev/null 2>&1 || { echo "Invalid JSON: _system/aiaast-capabilities.json" >&2; exit 1; }
jq -e . "${TARGET}/_system/golden-examples/golden-example-manifest.json" >/dev/null 2>&1 || { echo "Invalid JSON: _system/golden-examples/golden-example-manifest.json" >&2; exit 1; }
jq -e . "${TARGET}/_system/context-budget-profiles.json" >/dev/null 2>&1 || { echo "Invalid JSON: _system/context-budget-profiles.json" >&2; exit 1; }

python3 - <<'PY' "${TARGET}" "${REPO_MODE}"
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
repo_mode = sys.argv[2]

version_md = repo / "AIAST_VERSION.md"
template_version_file = repo / "_system" / ".template-version"
capabilities = json.loads((repo / "_system" / "aiaast-capabilities.json").read_text())
install_meta = json.loads((repo / "_system" / ".template-install.json").read_text())

match = re.search(r"^- Current version:\s*`([^`]+)`\s*$", version_md.read_text(), re.MULTILINE)
if not match:
    print("Could not parse version from AIAST_VERSION.md", file=sys.stderr)
    raise SystemExit(1)

versions = {
    "AIAST_VERSION.md": match.group(1).strip(),
    "_system/.template-version": template_version_file.read_text().strip(),
    "_system/aiaast-capabilities.json.template_version": str(capabilities.get("template_version", "")).strip(),
    "_system/.template-install.json.template_version": str(install_meta.get("template_version", "")).strip(),
    "_system/instruction-precedence.json.template_version": str(
        json.loads((repo / "_system" / "instruction-precedence.json").read_text()).get("template_version", "")
    ).strip(),
}
unique_versions = {value for value in versions.values() if value}
if len(unique_versions) != 1:
    print("Template version mismatch across metadata surfaces:", file=sys.stderr)
    for key, value in versions.items():
        print(f"- {key}: {value}", file=sys.stderr)
    raise SystemExit(1)

if str(install_meta.get("template_name", "")).strip() != "AIAST":
    print("_system/.template-install.json must declare template_name AIAST", file=sys.stderr)
    raise SystemExit(1)

install_mode = str(install_meta.get("install_mode", "")).strip()
last_event = str(install_meta.get("last_event", "")).strip()

if repo_mode == "template":
    if install_mode != "template-placeholder" or last_event != "template-source":
        print("Template mode requires template-placeholder install metadata in the source template", file=sys.stderr)
        raise SystemExit(1)
elif install_mode == "template-placeholder":
    print("Installed repos must not keep template-placeholder install metadata", file=sys.stderr)
    raise SystemExit(1)
PY

python3 - <<'PY' "${TARGET}/_system/mcp/servers.codex.example.toml"
import pathlib
import sys
import tomllib

try:
    tomllib.loads(pathlib.Path(sys.argv[1]).read_text())
except Exception as exc:
    print(f"Invalid TOML: _system/mcp/servers.codex.example.toml: {exc}", file=sys.stderr)
    sys.exit(1)
PY

INFERRED_TEMPLATE_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
RESOLVED_TARGET="$(cd -- "${TARGET}" && pwd)"

if [[ "${INFERRED_TEMPLATE_ROOT}" != "${RESOLVED_TARGET}" ]]; then
  # Scan installed repo files for leaked source-template absolute paths while
  # excluding VCS internals that can contain unrelated transient strings.
  if rg -n "${INFERRED_TEMPLATE_ROOT}" "${TARGET}" \
    --glob '!**/.git/**' \
    --glob '!bootstrap/validate-system.sh' >/dev/null 2>&1; then
    echo "Found forbidden absolute master-template path inside installed system" >&2
    exit 1
  fi
fi

if [[ ${STRICT} -eq 1 ]]; then
  if [[ "${REPO_MODE}" != "template" ]] && rg -n '^- App name:\s*$' "${TARGET}/_system/PROJECT_PROFILE.md" >/dev/null 2>&1; then
    echo "Strict mode failed: app name is still blank in PROJECT_PROFILE.md" >&2
    exit 1
  fi
fi

strict_gate_flag=()
[[ ${STRICT} -eq 1 ]] && strict_gate_flag+=(--strict)

# Sub-validators run quietly on success so CI logs stay readable; on failure,
# print their full output (otherwise a root-vs-owner mismatch looks like a
# silent exit 1 with no diagnostics).
_run_aiaast_subvalidator() {
  local label="$1"
  shift
  local tmp
  tmp="$(mktemp 2>/dev/null || mktemp -t aiaast_validate.XXXXXX)"
  if "$@" >"${tmp}" 2>&1; then
    rm -f "${tmp}"
    return 0
  fi
  echo "validate-system: sub-check '${label}' failed" >&2
  cat "${tmp}" >&2
  rm -f "${tmp}"
  return 1
}

_run_aiaast_subvalidator "validate-instruction-layer" \
  bash "${VALIDATOR_ROOT}/bootstrap/validate-instruction-layer.sh" "${TARGET}" --validator-root "${VALIDATOR_ROOT}"
_run_aiaast_subvalidator "check-instruction-domain-alignment" \
  bash "${VALIDATOR_ROOT}/bootstrap/check-instruction-domain-alignment.sh" "${TARGET}" --validate-manifest
_run_aiaast_subvalidator "check-system-awareness" \
  bash "${VALIDATOR_ROOT}/bootstrap/check-system-awareness.sh" "${TARGET}"
_run_aiaast_subvalidator "check-repo-permissions" \
  bash "${VALIDATOR_ROOT}/bootstrap/check-repo-permissions.sh" "${TARGET}"
_run_aiaast_subvalidator "check-runtime-foundations" \
  bash "${VALIDATOR_ROOT}/bootstrap/check-runtime-foundations.sh" "${TARGET}"
_run_aiaast_subvalidator "check-network-bindings" \
  bash "${VALIDATOR_ROOT}/bootstrap/check-network-bindings.sh" "${TARGET}" --include-template-assets
_run_aiaast_subvalidator "check-delivery-gate-alignment" \
  bash "${VALIDATOR_ROOT}/bootstrap/check-delivery-gate-alignment.sh" "${TARGET}" "${strict_gate_flag[@]}"
_run_aiaast_subvalidator "check-environment" \
  bash "${VALIDATOR_ROOT}/bootstrap/check-environment.sh" "${TARGET}"
_run_aiaast_subvalidator "validate-mcp-health" \
  bash "${VALIDATOR_ROOT}/bootstrap/validate-mcp-health.sh" "${TARGET}"

echo "system_ok"
