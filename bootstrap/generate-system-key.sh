#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: generate-system-key.sh [target-repo] [--output <path>] [--write]

Generate a deterministic agent-facing key for every AIAST-managed file.
EOF
}

TARGET_REPO=""
OUTPUT_PATH=""
WRITE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      OUTPUT_PATH="${2:-}"
      shift 2
      ;;
    --write)
      WRITE=1
      shift
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

if [[ ${WRITE} -eq 1 ]]; then
  aiaast_assert_non_root_for_repo_writes
fi

if [[ ! -d "${TARGET_REPO}" ]]; then
  echo "Target repo does not exist: ${TARGET_REPO}" >&2
  exit 1
fi

TARGET_REPO="$(cd -- "${TARGET_REPO}" && pwd)"

if [[ ${WRITE} -eq 1 && -z "${OUTPUT_PATH}" ]]; then
  OUTPUT_PATH="${TARGET_REPO}/_system/KEY.md"
fi

mapfile -t managed_files < <(aiaast_print_managed_files "${TARGET_REPO}")

python3 - <<'PY' "${TARGET_REPO}" "${OUTPUT_PATH}" "${SCRIPT_DIR}/lib/aiaast-lib.sh" "${WRITE}" "${managed_files[@]}"
from __future__ import annotations

import json
import shlex
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

repo_root = Path(sys.argv[1]).resolve()
output_path = sys.argv[2]
lib_path = Path(sys.argv[3]).resolve()
write_enabled = sys.argv[4] == "1"
managed_files = list(sys.argv[5:])


def shell_out(func: str, rel: str) -> str:
    quoted_lib = shlex.quote(str(lib_path))
    cmd = (
        f"source {quoted_lib} >/dev/null 2>&1 && "
        f"{func} {shlex.quote(rel)}"
    )
    result = subprocess.run(
        ["bash", "-lc", cmd],
        cwd=repo_root,
        text=True,
        capture_output=True,
        check=True,
    )
    return result.stdout.strip()


def pretty_name(rel: str) -> str:
    name = Path(rel).name
    for suffix in (
        ".json.example",
        ".yml.example",
        ".yaml.example",
        ".service",
        ".timer",
        ".example",
        ".json",
        ".yaml",
        ".yml",
        ".md",
        ".mdc",
        ".sh",
    ):
        if name.endswith(suffix):
            name = name[: -len(suffix)]
            break
    name = name.replace(".", " ").replace("-", " ").replace("_", " ")
    words = []
    acronyms = {
        "ai": "AI",
        "api": "API",
        "ci": "CI",
        "cli": "CLI",
        "mcp": "MCP",
        "ui": "UI",
        "ux": "UX",
        "llm": "LLM",
        "json": "JSON",
        "yaml": "YAML",
        "aiaast": "AIAST",
        "mdc": "MDC",
    }
    for word in name.split():
        words.append(acronyms.get(word.lower(), word.capitalize()))
    return " ".join(words) or rel


def register_exact(path: str, purpose: str, when: str) -> tuple[str, str]:
    return purpose, when


exact = {
    "AGENTS.md": register_exact(
        "AGENTS.md",
        "Primary repo contract for every coding agent and tool.",
        "Read first at session start and before meaningful edits.",
    ),
    "CLAUDE.md": register_exact(
        "CLAUDE.md",
        "Claude-specific adapter entrypoint layered on top of the shared repo contract.",
        "Load when Claude is the active host or when adapter wording changes.",
    ),
    "GEMINI.md": register_exact(
        "GEMINI.md",
        "Gemini-specific adapter entrypoint layered on top of the shared repo contract.",
        "Load when Gemini is the active host or when adapter wording changes.",
    ),
    "CODEX.md": register_exact(
        "CODEX.md",
        "Codex-specific adapter entrypoint layered on top of the shared repo contract.",
        "Load when Codex is the active host or when adapter wording changes.",
    ),
    "WINDSURF.md": register_exact(
        "WINDSURF.md",
        "Windsurf-specific adapter entrypoint layered on top of the shared repo contract.",
        "Load when Windsurf is the active host or when adapter wording changes.",
    ),
    ".cursorrules": register_exact(
        ".cursorrules",
        "Cursor rules overlay for repo-local guidance.",
        "Use when Cursor is loading repo rules or when Cursor policy changes.",
    ),
    ".windsurfrules": register_exact(
        ".windsurfrules",
        "Windsurf rules overlay for repo-local guidance.",
        "Use when Windsurf is loading repo rules or when Windsurf policy changes.",
    ),
    "DEEPSEEK.md": register_exact(
        "DEEPSEEK.md",
        "DeepSeek-specific adapter entrypoint layered on top of the shared repo contract.",
        "Load when DeepSeek is the active host or when adapter wording changes.",
    ),
    "PEARAI.md": register_exact(
        "PEARAI.md",
        "PearAI-specific adapter entrypoint layered on top of the shared repo contract.",
        "Load when PearAI is the active host or when adapter wording changes.",
    ),
    "LOCAL_MODELS.md": register_exact(
        "LOCAL_MODELS.md",
        "Adapter entrypoint for local models (Ollama, LLaMA, Mistral) layered on the shared contract.",
        "Load when using a local model or when adapter wording changes.",
    ),
    ".aider.conf.yml": register_exact(
        ".aider.conf.yml",
        "Aider configuration overlay that loads AIAST context files into Aider sessions.",
        "Load when Aider is the active tool or when adapter wording changes.",
    ),
    ".continuerules": register_exact(
        ".continuerules",
        "Continue.dev adapter entrypoint layered on top of the shared repo contract.",
        "Load when Continue.dev is the active tool or when adapter wording changes.",
    ),
    ".clinerules": register_exact(
        ".clinerules",
        "Cline (Roo Code) adapter entrypoint layered on top of the shared repo contract.",
        "Load when Cline is the active tool or when adapter wording changes.",
    ),
    "AIAST_VERSION.md": register_exact(
        "AIAST_VERSION.md",
        "Human-readable installed AIAST version marker.",
        "Check when confirming template version or updating release metadata.",
    ),
    "AIAST_CHANGELOG.md": register_exact(
        "AIAST_CHANGELOG.md",
        "Installable AIAST product changelog.",
        "Update when the shipped system changes in a user-visible or architectural way.",
    ),
    "TODO.md": register_exact(
        "TODO.md",
        "Active actionable queue for the installed repo.",
        "Update during execution and before handoff when tasks complete or new tasks appear.",
    ),
    "FIXME.md": register_exact(
        "FIXME.md",
        "Known defects, debt, and unresolved issues.",
        "Update when something is intentionally left broken, risky, or incomplete.",
    ),
    "WHERE_LEFT_OFF.md": register_exact(
        "WHERE_LEFT_OFF.md",
        "Primary resume packet for the next agent or session.",
        "Update at the end of each meaningful work slice.",
    ),
    "CHANGELOG.md": register_exact(
        "CHANGELOG.md",
        "Repo-facing change history for the app project.",
        "Update when shipped behavior or architecture changes.",
    ),
    "PLAN.md": register_exact(
        "PLAN.md",
        "Current execution slice and ordered plan.",
        "Use while actively driving the current implementation phase.",
    ),
    "PRODUCT_BRIEF.md": register_exact(
        "PRODUCT_BRIEF.md",
        "Product intent, user outcomes, and chosen build shape.",
        "Update when product direction or blueprint choice becomes more concrete.",
    ),
    "ROADMAP.md": register_exact(
        "ROADMAP.md",
        "Medium-term sequencing beyond the current plan.",
        "Use when placing the current slice in broader delivery order.",
    ),
    "DESIGN_NOTES.md": register_exact(
        "DESIGN_NOTES.md",
        "Durable product and UX direction notes.",
        "Update when design choices or UI rationale change.",
    ),
    "ARCHITECTURE_NOTES.md": register_exact(
        "ARCHITECTURE_NOTES.md",
        "Durable structural and technical design notes.",
        "Update when architecture, boundaries, or major technical decisions change.",
    ),
    "RESEARCH_NOTES.md": register_exact(
        "RESEARCH_NOTES.md",
        "Evidence log for experiments, references, and findings.",
        "Use when the work produces facts worth keeping beyond the current session.",
    ),
    "TEST_STRATEGY.md": register_exact(
        "TEST_STRATEGY.md",
        "Verification intent and coverage plan.",
        "Update when validation expectations, commands, or coverage priorities change.",
    ),
    "RISK_REGISTER.md": register_exact(
        "RISK_REGISTER.md",
        "Active delivery, quality, security, and operational risks.",
        "Update when new risks appear or mitigation status changes.",
    ),
    "RELEASE_NOTES.md": register_exact(
        "RELEASE_NOTES.md",
        "Operator-facing summary of current release behavior and known edges.",
        "Update when release posture or notable changes shift.",
    ),
    "README.md": register_exact(
        "README.md",
        "Human-oriented AIAST overview when the app repo does not already own the root README.",
        "Read during orientation or update when installable overview behavior changes.",
    ),
    "AI_SYSTEM_README.md": register_exact(
        "AI_SYSTEM_README.md",
        "Human-oriented AIAST overview when the app repo keeps its own root README.",
        "Read during orientation or update when installable overview behavior changes.",
    ),
    "_system/KEY.md": register_exact(
        "_system/KEY.md",
        "Exhaustive agent-facing key for every AIAST-managed file.",
        "Use when you need to understand the full system surface without guessing which files matter.",
    ),
    "_system/PROJECT_PROFILE.md": register_exact(
        "_system/PROJECT_PROFILE.md",
        "Repo-specific operational truth about languages, structure, packaging, and validation commands.",
        "Read early in every session and update when project reality becomes clearer.",
    ),
    "_system/INSTRUCTION_PRECEDENCE_CONTRACT.md": register_exact(
        "_system/INSTRUCTION_PRECEDENCE_CONTRACT.md",
        "Conflict-resolution contract for repo-local, host-level, and adapter-level instructions.",
        "Read before trusting upstream orchestration over repo-local truth.",
    ),
    "_system/REPO_OPERATING_PROFILE.md": register_exact(
        "_system/REPO_OPERATING_PROFILE.md",
        "Compact machine-friendly summary of the repo operating model.",
        "Use when a host needs fast repo ingestion without reading the entire system.",
    ),
    "_system/CONTEXT_INDEX.md": register_exact(
        "_system/CONTEXT_INDEX.md",
        "Map of the operating-system surfaces and where each type of truth lives.",
        "Read early when orienting to the system or locating the right file to update.",
    ),
    "_system/LOAD_ORDER.md": register_exact(
        "_system/LOAD_ORDER.md",
        "Recommended read order for loading the system efficiently.",
        "Use when context is limited or when a host needs a deterministic startup sequence.",
    ),
    "_system/SYSTEM_ORCHESTRATION_GUIDE.md": register_exact(
        "_system/SYSTEM_ORCHESTRATION_GUIDE.md",
        "Meta-map: how core surfaces connect, recommended review/validation order, evolution and conflict pointers.",
        "Read once when onboarding, consolidating systems, or when you need a single checklist instead of scattered entry points.",
    ),
    "_system/WORKING_FILES_GUIDE.md": register_exact(
        "_system/WORKING_FILES_GUIDE.md",
        "Guide to the role of each working-state file.",
        "Read when deciding where new project truth or progress belongs.",
    ),
    "_system/TEMPLATE_NEUTRALITY_POLICY.md": register_exact(
        "_system/TEMPLATE_NEUTRALITY_POLICY.md",
        "Rules that keep the source template reusable across future repos.",
        "Use when changing installable defaults or working-file seed content.",
    ),
    "_system/GOLDEN_EXAMPLES_POLICY.md": register_exact(
        "_system/GOLDEN_EXAMPLES_POLICY.md",
        "Policy for using curated examples without copying donor-app truth.",
        "Read before drafting new system docs, prompts, or working-file structures.",
    ),
    "_system/MASTER_SYSTEM_PROMPT.md": register_exact(
        "_system/MASTER_SYSTEM_PROMPT.md",
        "Canonical shared operating prompt for the local system.",
        "Use when reasoning about the common behavioral contract across hosts.",
    ),
    "_system/PROJECT_RULES.md": register_exact(
        "_system/PROJECT_RULES.md",
        "Repo-wide non-negotiable working rules.",
        "Read whenever the task could affect boundaries, truthfulness, or workflow rules.",
    ),
    "_system/MEMORY_RULES.md": register_exact(
        "_system/MEMORY_RULES.md",
        "Rules for what belongs in durable repo memory versus transient chat context.",
        "Use when deciding whether a fact should be persisted.",
    ),
    "_system/EXECUTION_PROTOCOL.md": register_exact(
        "_system/EXECUTION_PROTOCOL.md",
        "How work should be executed, validated, and handed off.",
        "Read before starting or reshaping a meaningful execution slice.",
    ),
    "_system/MULTI_AGENT_COORDINATION.md": register_exact(
        "_system/MULTI_AGENT_COORDINATION.md",
        "Turn-taking and ownership rules for multi-agent work.",
        "Use when planning delegated or parallel execution.",
    ),
    "_system/AGENT_ROLE_CATALOG.md": register_exact(
        "_system/AGENT_ROLE_CATALOG.md",
        "Canonical role catalog and ownership model for delegated work.",
        "Read when selecting or defining agent roles.",
    ),
    "_system/AGENT_DISCOVERY_MATRIX.md": register_exact(
        "_system/AGENT_DISCOVERY_MATRIX.md",
        "Matrix of which tools and hosts load which repo surfaces.",
        "Use when checking host coverage or adapter expectations.",
    ),
    "_system/SYSTEM_AWARENESS_PROTOCOL.md": register_exact(
        "_system/SYSTEM_AWARENESS_PROTOCOL.md",
        "Contract for how AIAST tracks and validates its own managed surfaces.",
        "Read when changing registries, file maps, or self-awareness checks.",
    ),
    "_system/HALLUCINATION_DEFENSE_PROTOCOL.md": register_exact(
        "_system/HALLUCINATION_DEFENSE_PROTOCOL.md",
        "Protocol for grounding claims in repo-local evidence.",
        "Use when confidence or claimed system state could drift from evidence.",
    ),
    "_system/SYSTEM_REGISTRY.json": register_exact(
        "_system/SYSTEM_REGISTRY.json",
        "Machine-readable inventory of AIAST-managed files.",
        "Use when tooling needs deterministic file coverage instead of prose guidance.",
    ),
    "_system/instruction-precedence.json": register_exact(
        "_system/instruction-precedence.json",
        "Machine-readable instruction-precedence manifest.",
        "Use when validating or exporting precedence behavior programmatically.",
    ),
    "_system/HOST_ADAPTER_POLICY.md": register_exact(
        "_system/HOST_ADAPTER_POLICY.md",
        "Policy for generated tool-entry and load-context adapter surfaces.",
        "Read when tool-specific entrypoints or overlays change.",
    ),
    "_system/HOST_BUNDLE_CONTRACT.md": register_exact(
        "_system/HOST_BUNDLE_CONTRACT.md",
        "Contract for self-contained bundles exported to external hosts.",
        "Read when a consumer cannot access repo-local paths directly.",
    ),
    "_system/host-adapter-manifest.json": register_exact(
        "_system/host-adapter-manifest.json",
        "Canonical machine-readable source for generated host adapters.",
        "Edit only when adapter inputs change, then regenerate the adapters.",
    ),
    "_system/README.md": register_exact(
        "_system/README.md",
        "Overview of what belongs inside the local operating-system directory.",
        "Read during first orientation to the `_system/` layer.",
    ),
    "_system/PROMPTS_INDEX.md": register_exact(
        "_system/PROMPTS_INDEX.md",
        "Index of prompt templates and prompt packs.",
        "Use when assembling or auditing prompt surfaces.",
    ),
    "_system/PROMPT_EMISSION_CONTRACT.md": register_exact(
        "_system/PROMPT_EMISSION_CONTRACT.md",
        "Rules for emitting prompts for external tools or hosts.",
        "Read when prompt-generation or host-export behavior changes.",
    ),
    "_system/SKILLS_INDEX.md": register_exact(
        "_system/SKILLS_INDEX.md",
        "Index of reusable skills and their intended roles.",
        "Use when deciding whether a capability should live as a skill.",
    ),
    "_system/QUICKSTART.md": register_exact(
        "_system/QUICKSTART.md",
        "One-page onboarding guide for new AIAST users.",
        "Read when first encountering the system or directing someone to the fastest start path.",
    ),
    "_system/ARCHITECTURE_DIAGRAM.md": register_exact(
        "_system/ARCHITECTURE_DIAGRAM.md",
        "ASCII box diagrams of the three-layer model, loading flow, adapter pipeline, and validation chain.",
        "Read when understanding the system architecture or explaining it to others.",
    ),
    "_system/TROUBLESHOOTING.md": register_exact(
        "_system/TROUBLESHOOTING.md",
        "Symptom-based FAQ for common AIAST issues and their fixes.",
        "Read when something is broken and you need a quick diagnosis path.",
    ),
    "_system/MIGRATION_GUIDE.md": register_exact(
        "_system/MIGRATION_GUIDE.md",
        "Migration paths from no agent system, Cursor-only, custom CLAUDE.md, or other frameworks.",
        "Read when onboarding a repo that already has some agent governance.",
    ),
    "_system/CONTEXT_BUDGET_STRATEGY.md": register_exact(
        "_system/CONTEXT_BUDGET_STRATEGY.md",
        "Four-tier context budget model (A/B/C/D) keyed by model context window size.",
        "Read when selecting which files to load for a context-constrained model.",
    ),
    "_system/context-budget-profiles.json": register_exact(
        "_system/context-budget-profiles.json",
        "Machine-readable tier assignments for 21 model families with context token counts.",
        "Use when emit-tiered-context.sh needs to resolve a model to a tier.",
    ),
    "_system/ENVIRONMENT_VALIDATION_CONTRACT.md": register_exact(
        "_system/ENVIRONMENT_VALIDATION_CONTRACT.md",
        "Scope and rules for environment-level checks (CLI tools, ports, env vars, disk space).",
        "Read when adding or adjusting environment validation behavior.",
    ),
    "_system/health-history.json": register_exact(
        "_system/health-history.json",
        "Append-only log of system-doctor results for trend tracking (50-entry rotation).",
        "Read by report-health-trends.sh; written by system-doctor.sh --record.",
    ),
    "_system/AGENT_PERFORMANCE_GUIDE.md": register_exact(
        "_system/AGENT_PERFORMANCE_GUIDE.md",
        "Model capability dimensions, task-to-model mapping, and multi-agent delegation guidance.",
        "Read when choosing which model to use for a specific task type.",
    ),
    "_system/agent-performance-profiles.json": register_exact(
        "_system/agent-performance-profiles.json",
        "Machine-readable ratings for 19 model families across quality, planning, review, speed, and cost.",
        "Use when tooling needs programmatic model selection based on capability.",
    ),
    "_system/PROMPT_EFFECTIVENESS_TRACKING.md": register_exact(
        "_system/PROMPT_EFFECTIVENESS_TRACKING.md",
        "Protocol for measuring which prompt packs succeed or fail per model and task type.",
        "Read when recording or analyzing prompt effectiveness data.",
    ),
    "_system/PLUGIN_CONTRACT.md": register_exact(
        "_system/PLUGIN_CONTRACT.md",
        "Contract for optional AIAST extensions with 12 hook points, manifest schema, and lifecycle.",
        "Read when creating, validating, or understanding plugins.",
    ),
    "bootstrap/README.md": register_exact(
        "bootstrap/README.md",
        "Operator guide to the install, repair, validation, and generation scripts.",
        "Read before running lifecycle scripts or debugging bootstrap flows.",
    ),
    "bootstrap/init-project.sh": register_exact(
        "bootstrap/init-project.sh",
        "Fresh-install entrypoint that copies and initializes AIAST into a target repo.",
        "Run when bootstrapping a repo that does not yet have AIAST.",
    ),
    "bootstrap/install-missing-files.sh": register_exact(
        "bootstrap/install-missing-files.sh",
        "Additive recovery flow for newly introduced template files and safe defaults.",
        "Run when an installed repo is missing newer AIAST-managed surfaces.",
    ),
    "bootstrap/update-template.sh": register_exact(
        "bootstrap/update-template.sh",
        "Additive upgrade flow for refreshing an installed repo from a newer source template.",
        "Run when a repo already has AIAST and should be updated to a newer release.",
    ),
    "bootstrap/repair-system.sh": register_exact(
        "bootstrap/repair-system.sh",
        "Repair flow for restoring missing or drifted system-managed files.",
        "Run when integrity, awareness, or drift checks say the local system is damaged.",
    ),
    "bootstrap/uninstall-system.sh": register_exact(
        "bootstrap/uninstall-system.sh",
        "Removal flow for uninstalling the operating layer while leaving runtime code alone.",
        "Run only when intentionally removing AIAST from a repo.",
    ),
    "bootstrap/validate-system.sh": register_exact(
        "bootstrap/validate-system.sh",
        "Strict structural validator for required files and baseline portability.",
        "Run after meaningful system changes or before trusting an installed repo state.",
    ),
    "bootstrap/validate-instruction-layer.sh": register_exact(
        "bootstrap/validate-instruction-layer.sh",
        "Validator for precedence, operating-profile, and prompt-emission surfaces.",
        "Run when instruction, adapter, or host-ingestion surfaces change.",
    ),
    "bootstrap/verify-integrity.sh": register_exact(
        "bootstrap/verify-integrity.sh",
        "Hash generator and verifier for AIAST-managed files.",
        "Run when confirming or refreshing integrity state.",
    ),
    "bootstrap/generate-system-key.sh": register_exact(
        "bootstrap/generate-system-key.sh",
        "Generator for the exhaustive agent-facing system key.",
        "Run when the managed file set or file-role wording changes.",
    ),
    "bootstrap/generate-system-registry.sh": register_exact(
        "bootstrap/generate-system-registry.sh",
        "Generator for the machine-readable managed-file registry.",
        "Run when the managed file set changes.",
    ),
    "bootstrap/generate-host-adapters.sh": register_exact(
        "bootstrap/generate-host-adapters.sh",
        "Generator for tool-entry and host-adapter surfaces.",
        "Run when host-adapter-manifest inputs change.",
    ),
    "bootstrap/generate-operating-profile.sh": register_exact(
        "bootstrap/generate-operating-profile.sh",
        "Generator for the compact repo operating profile.",
        "Run when installable operating-model facts change.",
    ),
    "bootstrap/check-system-awareness.sh": register_exact(
        "bootstrap/check-system-awareness.sh",
        "Validator for registry coverage and critical path references across core docs.",
        "Run when file inventories or core doc maps change.",
    ),
    "bootstrap/system-doctor.sh": register_exact(
        "bootstrap/system-doctor.sh",
        "Full diagnostic wrapper for awareness, integrity, drift, and hallucination checks. Supports --report and --record.",
        "Run when the system picture feels inconsistent or suspect.",
    ),
    "bootstrap/emit-tiered-context.sh": register_exact(
        "bootstrap/emit-tiered-context.sh",
        "Emits a tier-appropriate context load sequence based on model context window.",
        "Run with --tier A|B|C|D or --model <name> to get the right file list for a given model.",
    ),
    "bootstrap/validate-plugin.sh": register_exact(
        "bootstrap/validate-plugin.sh",
        "Validates a plugin manifest against the PLUGIN_CONTRACT schema and allowed hook points.",
        "Run when creating or verifying a plugin.",
    ),
    "bootstrap/discover-plugins.sh": register_exact(
        "bootstrap/discover-plugins.sh",
        "Scans for installed plugins and reports their name, version, hooks, and enabled status.",
        "Run when auditing or listing available plugins.",
    ),
    "bootstrap/check-environment.sh": register_exact(
        "bootstrap/check-environment.sh",
        "Validates runtime prerequisites: CLI tools, ports, disk space, env files.",
        "Run when diagnosing environment issues or after changing project profile.",
    ),
    "bootstrap/generate-diagnostic-report.sh": register_exact(
        "bootstrap/generate-diagnostic-report.sh",
        "Aggregates AIAST version, validation, environment, drift, and plugin status into one report.",
        "Run when you need a complete health snapshot.",
    ),
    "bootstrap/report-health-trends.sh": register_exact(
        "bootstrap/report-health-trends.sh",
        "Reads health-history.json and computes pass/warn/fail trends over recent entries.",
        "Run when assessing whether system health is improving or degrading.",
    ),
    "bootstrap/run-sast.sh": register_exact(
        "bootstrap/run-sast.sh",
        "Dispatches to semgrep, bandit, eslint-security, and gosec based on detected languages.",
        "Run when performing static application security testing.",
    ),
    "bootstrap/check-supply-chain.sh": register_exact(
        "bootstrap/check-supply-chain.sh",
        "Runs language-specific dependency audit tools (npm, pip, cargo, go) and license checks.",
        "Run when auditing supply chain security.",
    ),
    "bootstrap/scan-container.sh": register_exact(
        "bootstrap/scan-container.sh",
        "Scans Dockerfiles and container images with trivy, grype, hadolint, and static lint.",
        "Run when verifying container security posture.",
    ),
    "bootstrap/check-network-bindings.sh": register_exact(
        "bootstrap/check-network-bindings.sh",
        "Detects wildcard network bindings (0.0.0.0, ::) that violate the loopback-only contract.",
        "Run when verifying network security compliance.",
    ),
    "bootstrap/wizard.sh": register_exact(
        "bootstrap/wizard.sh",
        "Interactive AIAST setup wizard with stack detection, profile configuration, and blueprint selection.",
        "Run for guided first-time setup of a new repo.",
    ),
    "bootstrap/upgrade-assistant.sh": register_exact(
        "bootstrap/upgrade-assistant.sh",
        "Interactive upgrade guide with version diff, breaking change warnings, and post-upgrade validation.",
        "Run when upgrading an installed repo to a newer AIAST version.",
    ),
    "bootstrap/track-semantic-changes.sh": register_exact(
        "bootstrap/track-semantic-changes.sh",
        "Classifies git diff changes as structural, contractual, cosmetic, or behavioral.",
        "Run when assessing the impact of recent changes.",
    ),
}

section_order = [
    "entrypoint",
    "system-metadata",
    "working-state",
    "bootstrap",
    "system-core",
    "system-context",
    "review-playbook",
    "prompting",
    "starter-blueprint",
    "mcp",
    "ci",
    "packaging",
    "plugin",
    "systemd",
    "cursor-agent",
    "cursor-command",
    "cursor-rule",
    "cursor-skill",
    "cursor-overlay",
    "copilot-overlay",
    "unclassified",
]

section_meta = {
    "entrypoint": (
        "Entry Surfaces",
        "These files are the direct entrypoints or host overlays agents encounter at session start.",
    ),
    "system-metadata": (
        "System Metadata",
        "These files describe versioned AIAST identity and installable system overview state.",
    ),
    "working-state": (
        "Working State",
        "These files hold the repo's active execution, continuity, design, validation, and release truth.",
    ),
    "bootstrap": (
        "Bootstrap And Lifecycle",
        "These files install, update, repair, validate, and generate the AIAST operating layer.",
    ),
    "system-core": (
        "System Core",
        "These files define the installable operating-system contracts, policies, guides, manifests, and indexes.",
    ),
    "system-context": (
        "Durable Context",
        "These files hold long-lived project memory and integration state.",
    ),
    "review-playbook": (
        "Review Playbooks",
        "These files provide structured review passes for major quality domains.",
    ),
    "prompting": (
        "Prompting Assets",
        "These files support prompt emission, reusable prompt templates, and prompt packs.",
    ),
    "starter-blueprint": (
        "Starter Blueprints",
        "These files describe the canonical starter shapes used during greenfield repo setup.",
    ),
    "mcp": (
        "MCP Surfaces",
        "These files describe optional MCP usage, cataloging, and fallback behavior.",
    ),
    "ci": (
        "CI Surfaces",
        "These files are reusable automation examples for CI pipelines.",
    ),
    "packaging": (
        "Packaging Surfaces",
        "These files describe packaging policy and provide reusable packaging templates.",
    ),
    "plugin": (
        "Plugin Surfaces",
        "These files define optional AIAST extension hooks.",
    ),
    "systemd": (
        "Systemd Surfaces",
        "These files provide hardened systemd references and examples.",
    ),
    "cursor-agent": (
        "Cursor Agent Roles",
        "These files define Cursor-specific delegated agent role prompts.",
    ),
    "cursor-command": (
        "Cursor Commands",
        "These files define Cursor slash-command prompts and guided workflows.",
    ),
    "cursor-rule": (
        "Cursor Rules",
        "These files are auto-loaded Cursor rule overlays.",
    ),
    "cursor-skill": (
        "Cursor Skills",
        "These files back Cursor skill surfaces and skill-local commands.",
    ),
    "cursor-overlay": (
        "Cursor Overlays",
        "These files are supporting Cursor-specific overlays that do not fit the narrower agent, command, rule, or skill buckets.",
    ),
    "copilot-overlay": (
        "Copilot Overlay",
        "These files provide repo-local guidance to GitHub Copilot.",
    ),
    "unclassified": (
        "Unclassified",
        "These files are managed but do not currently fit a more specific category.",
    ),
}


def generic_entry(rel: str, category: str) -> tuple[str, str]:
    title = pretty_name(rel)
    if rel.startswith("bootstrap/lib/"):
        return (
            f"Shared bootstrap helper library for {title}.",
            "Used indirectly by install, repair, update, generation, and validation scripts.",
        )
    if rel.startswith("bootstrap/templates/runtime/"):
        return (
            f"Bootstrap template asset for {title}.",
            "Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.",
        )
    if rel.startswith("_system/context/"):
        return (
            f"Durable context record for {title}.",
            "Read during resume and update when the underlying project truth changes.",
        )
    if rel.startswith("_system/golden-examples/patterns/"):
        return (
            f"Neutral pattern guide for {title}.",
            "Use when drafting or revising the same kind of system surface without copying donor-app facts.",
        )
    if rel.startswith("_system/golden-examples/working-files/"):
        return (
            f"Quality-bar working-file example for {title}.",
            "Use when shaping the corresponding repo-local working file.",
        )
    if rel.startswith("_system/golden-examples/"):
        return (
            f"Golden-example asset for {title}.",
            "Use when auditing or refreshing the curated example pack.",
        )
    if rel.startswith("_system/review-playbooks/"):
        return (
            f"Structured review playbook for {title}.",
            "Run it when performing that named review pass.",
        )
    if rel.startswith("_system/starter-blueprints/"):
        return (
            f"Starter blueprint contract for {title}.",
            "Read when choosing, recommending, or applying that build shape.",
        )
    if rel.startswith("_system/prompt-packs/"):
        return (
            f"Prompt-pack asset for {title}.",
            "Load when generating prompts for the matching workflow or role.",
        )
    if rel.startswith("_system/prompt-templates/"):
        return (
            f"Prompt template for {title}.",
            "Use when assembling a task-specific prompt from reusable building blocks.",
        )
    if rel.startswith("_system/mcp/"):
        return (
            f"MCP reference for {title}.",
            "Read when selecting, cataloging, or recovering from MCP integrations.",
        )
    if rel.startswith("_system/ci/"):
        return (
            f"CI example for {title}.",
            "Use when wiring repo automation or comparing CI layouts.",
        )
    if rel.startswith("_system/packaging/templates/"):
        return (
            f"Reusable packaging template for {title}.",
            "Use when generating or validating the matching packaging target.",
        )
    if rel.startswith("_system/packaging/"):
        return (
            f"Packaging reference for {title}.",
            "Read when shaping release and distribution surfaces.",
        )
    if rel.startswith("_system/plugins/"):
        return (
            f"Plugin extension surface for {title}.",
            "Read when adding or validating optional AIAST extensions.",
        )
    if rel.startswith("_system/systemd/"):
        return (
            f"Systemd reference for {title}.",
            "Use when generating or validating hardened service or timer units.",
        )
    if rel.startswith(".cursor/agents/"):
        return (
            f"Cursor delegated-agent prompt for {title}.",
            "Used when the named Cursor agent role is invoked.",
        )
    if rel.startswith(".cursor/commands/"):
        return (
            f"Cursor command surface for {title}.",
            "Used when invoking that named Cursor command.",
        )
    if rel.startswith(".cursor/rules/"):
        return (
            f"Cursor rule overlay for {title}.",
            "Auto-loaded by Cursor to reinforce repo-local behavior.",
        )
    if rel.startswith(".cursor/skills/"):
        return (
            f"Cursor skill asset for {title}.",
            "Used when the corresponding Cursor skill is loaded.",
        )
    if rel.startswith(".cursor/"):
        return (
            f"Cursor overlay surface for {title}.",
            "Read or regenerate when Cursor-specific integration surfaces change.",
        )
    if rel.startswith(".github/"):
        return (
            f"GitHub Copilot overlay for {title}.",
            "Used when Copilot loads repo-local instructions.",
        )
    if rel.startswith("bootstrap/") and rel.endswith(".sh"):
        return (
            f"Bootstrap command for {title}.",
            "Run when performing the named install, repair, validation, emission, or generation task.",
        )
    if category == "entrypoint":
        return (
            f"Host-entry surface for {title}.",
            "Load when the matching tool is the active host.",
        )
    if category == "system-metadata":
        return (
            f"System metadata surface for {title}.",
            "Read when checking installed AIAST identity or overview state.",
        )
    if category == "working-state":
        return (
            f"Working-state surface for {title}.",
            "Update when the current execution, design, testing, or release truth changes.",
        )
    if category == "system-core":
        return (
            f"Core operating-system reference for {title}.",
            "Load when the task touches that named contract, policy, guide, or manifest.",
        )
    return (
        f"Managed AIAST surface for {title}.",
        "Use it when the task clearly touches the surface named by this file.",
    )


if output_path:
    resolved_output = Path(output_path)
    if not resolved_output.is_absolute():
        resolved_output = (repo_root / resolved_output).resolve()
    try:
        output_rel = str(resolved_output.relative_to(repo_root))
    except ValueError:
        output_rel = ""
    if output_rel and output_rel not in managed_files:
        managed_files.append(output_rel)

entries = []
for rel in sorted(set(managed_files)):
    category = shell_out("aiaast_path_category", rel)
    purpose, when = exact.get(rel, generic_entry(rel, category))
    entries.append(
        {
            "category": category,
            "path": rel,
            "purpose": purpose,
            "when": when,
        }
    )

groups: dict[str, list[dict[str, str]]] = defaultdict(list)
for entry in entries:
    groups[entry["category"]].append(entry)

lines = [
    "# System Key",
    "",
    "This file is the exhaustive agent-facing key for the installable AIAST surface.",
    "",
    f"It covers {len(entries)} managed files and is generated from the canonical managed-file inventory.",
    "",
    "## How To Use This File",
    "",
    "- Start here when you need to understand which files exist before editing or delegating.",
    "- Use `CONTEXT_INDEX.md` and `LOAD_ORDER.md` for the fastest read path, then use this key when you need full coverage.",
    "- Regenerate this file with `bootstrap/generate-system-key.sh <target-repo> --write` whenever the managed file set or file-role wording changes.",
    "",
    "## File Catalog",
    "",
]

for category in section_order:
    category_entries = groups.get(category, [])
    if not category_entries:
        continue
    title, intro = section_meta[category]
    lines.extend([f"### {title}", "", intro, ""])
    for entry in sorted(category_entries, key=lambda item: item["path"]):
        lines.append(f"- `{entry['path']}` - {entry['purpose']} {entry['when']}")
    lines.append("")

payload = "\n".join(lines).rstrip() + "\n"

if write_enabled:
    out = resolved_output
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(payload)
else:
    print(payload, end="")
PY

if [[ ${WRITE} -eq 1 ]]; then
  echo "Wrote system key to ${OUTPUT_PATH}"
fi
