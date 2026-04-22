# System Key

This file is the exhaustive agent-facing key for the installable AIAST surface.

It covers 494 managed files and is generated from the canonical managed-file inventory.

## How To Use This File

- Start here when you need to understand which files exist before editing or delegating.
- Use `CONTEXT_INDEX.md` and `LOAD_ORDER.md` for the fastest read path, then use this key when you need full coverage.
- Regenerate this file with `bootstrap/generate-system-key.sh <target-repo> --write` whenever the managed file set or file-role wording changes.

## File Catalog

### Entry Surfaces

These files are the direct entrypoints or host overlays agents encounter at session start.

- `.aider.conf.yml` - Aider configuration overlay that loads AIAST context files into Aider sessions. Load when Aider is the active tool or when adapter wording changes.
- `.clinerules` - Cline (Roo Code) adapter entrypoint layered on top of the shared repo contract. Load when Cline is the active tool or when adapter wording changes.
- `.continuerules` - Continue.dev adapter entrypoint layered on top of the shared repo contract. Load when Continue.dev is the active tool or when adapter wording changes.
- `.cursorrules` - Cursor rules overlay for repo-local guidance. Use when Cursor is loading repo rules or when Cursor policy changes.
- `.github/copilot-instructions.md` - GitHub Copilot overlay for Copilot Instructions. Used when Copilot loads repo-local instructions.
- `.windsurfrules` - Windsurf rules overlay for repo-local guidance. Use when Windsurf is loading repo rules or when Windsurf policy changes.
- `AGENTS.md` - Primary repo contract for every coding agent and tool. Read first at session start and before meaningful edits.
- `CLAUDE.md` - Claude-specific adapter entrypoint layered on top of the shared repo contract. Load when Claude is the active host or when adapter wording changes.
- `CODEX.md` - Codex-specific adapter entrypoint layered on top of the shared repo contract. Load when Codex is the active host or when adapter wording changes.
- `DEEPSEEK.md` - DeepSeek-specific adapter entrypoint layered on top of the shared repo contract. Load when DeepSeek is the active host or when adapter wording changes.
- `GEMINI.md` - Gemini-specific adapter entrypoint layered on top of the shared repo contract. Load when Gemini is the active host or when adapter wording changes.
- `LOCAL_MODELS.md` - Adapter entrypoint for local models (Ollama, LLaMA, Mistral) layered on the shared contract. Load when using a local model or when adapter wording changes.
- `PEARAI.md` - PearAI-specific adapter entrypoint layered on top of the shared repo contract. Load when PearAI is the active host or when adapter wording changes.
- `WINDSURF.md` - Windsurf-specific adapter entrypoint layered on top of the shared repo contract. Load when Windsurf is the active host or when adapter wording changes.

### System Metadata

These files describe versioned AIAST identity and installable system overview state.

- `AIAST_CHANGELOG.md` - Installable AIAST product changelog. Update when the shipped system changes in a user-visible or architectural way.
- `AIAST_VERSION.md` - Human-readable installed AIAST version marker. Check when confirming template version or updating release metadata.
- `README.md` - Human-oriented AIAST overview when the app repo does not already own the root README. Read during orientation or update when installable overview behavior changes.

### Working State

These files hold the repo's active execution, continuity, design, validation, and release truth.

- `ARCHITECTURE_NOTES.md` - Durable structural and technical design notes. Update when architecture, boundaries, or major technical decisions change.
- `CHANGELOG.md` - Repo-facing change history for the app project. Update when shipped behavior or architecture changes.
- `DESIGN_NOTES.md` - Durable product and UX direction notes. Update when design choices or UI rationale change.
- `FIXME.md` - Known defects, debt, and unresolved issues. Update when something is intentionally left broken, risky, or incomplete.
- `PLAN.md` - Current execution slice and ordered plan. Use while actively driving the current implementation phase.
- `PRODUCT_BRIEF.md` - Product intent, user outcomes, and chosen build shape. Update when product direction or blueprint choice becomes more concrete.
- `RELEASE_NOTES.md` - Operator-facing summary of current release behavior and known edges. Update when release posture or notable changes shift.
- `RESEARCH_NOTES.md` - Evidence log for experiments, references, and findings. Use when the work produces facts worth keeping beyond the current session.
- `RISK_REGISTER.md` - Active delivery, quality, security, and operational risks. Update when new risks appear or mitigation status changes.
- `ROADMAP.md` - Medium-term sequencing beyond the current plan. Use when placing the current slice in broader delivery order.
- `TEST_STRATEGY.md` - Verification intent and coverage plan. Update when validation expectations, commands, or coverage priorities change.
- `TODO.md` - Active actionable queue for the installed repo. Update during execution and before handoff when tasks complete or new tasks appear.
- `WHERE_LEFT_OFF.md` - Primary resume packet for the next agent or session. Update at the end of each meaningful work slice.

### Bootstrap And Lifecycle

These files install, update, repair, validate, and generate the AIAST operating layer.

- `bootstrap/README.md` - Operator guide to the install, repair, validation, and generation scripts. Read before running lifecycle scripts or debugging bootstrap flows.
- `bootstrap/apply-starter-blueprint.sh` - Bootstrap command for Apply Starter Blueprint. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/check-agent-orchestration.sh` - Bootstrap command for Check Agent Orchestration. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/check-agent-surface-integrity.sh` - Bootstrap command for Check Agent Surface Integrity. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/check-bootstrap-permissions.sh` - Bootstrap command for Check Bootstrap Permissions. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/check-delivery-gate-alignment.sh` - Bootstrap command for Check Delivery Gate Alignment. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/check-environment.sh` - Validates runtime prerequisites: CLI tools, ports, disk space, env files. Run when diagnosing environment issues or after changing project profile.
- `bootstrap/check-evidence-quality.sh` - Bootstrap command for Check Evidence Quality. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/check-hallucination.sh` - Bootstrap command for Check Hallucination. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/check-host-adapter-alignment.sh` - Bootstrap command for Check Host Adapter Alignment. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/check-host-bundle.sh` - Bootstrap command for Check Host Bundle. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/check-host-ingestion.sh` - Bootstrap command for Check Host Ingestion. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/check-install-boundary.sh` - Bootstrap command for Check Install Boundary. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/check-network-bindings.sh` - Detects wildcard network bindings (0.0.0.0, ::) that violate the loopback-only contract. Run when verifying network security compliance.
- `bootstrap/check-packaging-targets.sh` - Bootstrap command for Check Packaging Targets. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/check-placeholders.sh` - Bootstrap command for Check Placeholders. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/check-repo-permissions.sh` - Bootstrap command for Check Repo Permissions. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/check-runtime-foundations.sh` - Bootstrap command for Check Runtime Foundations. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/check-supply-chain.sh` - Runs language-specific dependency audit tools (npm, pip, cargo, go) and license checks. Run when auditing supply chain security.
- `bootstrap/check-swarm-fleet.sh` - Bootstrap command for Check Swarm Fleet. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/check-system-awareness.sh` - Validator for registry coverage and critical path references across core docs. Run when file inventories or core doc maps change.
- `bootstrap/check-working-file-staleness.sh` - Bootstrap command for Check Working File Staleness. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/compress-context-file.sh` - Bootstrap command for Compress Context File. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/configure-project-profile.sh` - Bootstrap command for Configure Project Profile. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/detect-drift.sh` - Bootstrap command for Detect Drift. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/detect-instruction-conflicts.sh` - Bootstrap command for Detect Instruction Conflicts. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/discover-plugins.sh` - Scans for installed plugins and reports their name, version, hooks, and enabled status. Run when auditing or listing available plugins.
- `bootstrap/emit-auxiliary-brief.sh` - Bootstrap command for Emit Auxiliary Brief. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/emit-host-bundle.sh` - Bootstrap command for Emit Host Bundle. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/emit-host-prompt.sh` - Bootstrap command for Emit Host Prompt. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/emit-tiered-context.sh` - Emits a tier-appropriate context load sequence based on model context window. Run with --tier A|B|C|D or --model <name> to get the right file list for a given model.
- `bootstrap/generate-diagnostic-report.sh` - Aggregates AIAST version, validation, environment, drift, and plugin status into one report. Run when you need a complete health snapshot.
- `bootstrap/generate-host-adapters.sh` - Generator for tool-entry and host-adapter surfaces. Run when host-adapter-manifest inputs change.
- `bootstrap/generate-operating-profile.sh` - Generator for the compact repo operating profile. Run when installable operating-model facts change.
- `bootstrap/generate-runtime-foundations.sh` - Bootstrap command for Generate Runtime Foundations. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/generate-system-key.sh` - Generator for the exhaustive agent-facing system key. Run when the managed file set or file-role wording changes.
- `bootstrap/generate-system-registry.sh` - Generator for the machine-readable managed-file registry. Run when the managed file set changes.
- `bootstrap/generate-systemd-unit.sh` - Bootstrap command for Generate Systemd Unit. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/git-swarm-manager.sh` - Bootstrap command for Git Swarm Manager. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/heal-system.sh` - Bootstrap command for Heal System. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/init-project.sh` - Fresh-install entrypoint that copies and initializes AIAST into a target repo. Run when bootstrapping a repo that does not yet have AIAST.
- `bootstrap/install-autonomous-guardrails.sh` - Bootstrap command for Install Autonomous Guardrails. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/install-missing-files.sh` - Additive recovery flow for newly introduced template files and safe defaults. Run when an installed repo is missing newer AIAST-managed surfaces.
- `bootstrap/lib/aiaast-lib.sh` - Shared bootstrap helper library for AIAST Lib. Used indirectly by install, repair, update, generation, and validation scripts.
- `bootstrap/migrate-agent-surface-upgrade.sh` - Bootstrap command for Migrate Agent Surface Upgrade. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/patch-agent-surface-contracts.sh` - Bootstrap command for Patch Agent Surface Contracts. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/print-agent-map.sh` - Bootstrap command for Print Agent Map. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/recommend-starter-blueprint.sh` - Bootstrap command for Recommend Starter Blueprint. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/repair-myappz-root-ownership.sh` - Bootstrap command for Repair Myappz Root Ownership. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/repair-swarm-integrity.sh` - Bootstrap command for Repair Swarm Integrity. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/repair-system.sh` - Repair flow for restoring missing or drifted system-managed files. Run when integrity, awareness, or drift checks say the local system is damaged.
- `bootstrap/report-health-trends.sh` - Reads health-history.json and computes pass/warn/fail trends over recent entries. Run when assessing whether system health is improving or degrading.
- `bootstrap/resume-from-checkpoint.sh` - Bootstrap command for Resume From Checkpoint. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/run-autonomous-guardrails.sh` - Bootstrap command for Run Autonomous Guardrails. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/run-sast.sh` - Dispatches to semgrep, bandit, eslint-security, and gosec based on detected languages. Run when performing static application security testing.
- `bootstrap/scaffold-system.sh` - Bootstrap command for Scaffold System. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/scan-container.sh` - Scans Dockerfiles and container images with trivy, grype, hadolint, and static lint. Run when verifying container security posture.
- `bootstrap/scan-security.sh` - Bootstrap command for Scan Security. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/seed-product-brief.sh` - Bootstrap command for Seed Product Brief. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/seed-risk-register.sh` - Bootstrap command for Seed Risk Register. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/seed-test-strategy.sh` - Bootstrap command for Seed Test Strategy. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/seed-working-state.sh` - Bootstrap command for Seed Working State. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/suggest-project-profile.sh` - Bootstrap command for Suggest Project Profile. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/sync-agent-adapters.sh` - Bootstrap command for Sync Agent Adapters. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/sync-metasystem-contracts.sh` - Bootstrap command for Sync Metasystem Contracts. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/system-doctor.sh` - Full diagnostic wrapper for awareness, integrity, drift, and hallucination checks. Supports --report and --record. Run when the system picture feels inconsistent or suspect.
- `bootstrap/templates/runtime/.credits-hidden` - Bootstrap template asset for Credits Hidden. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/LICENSE` - Bootstrap template asset for License. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/NOTICE` - Bootstrap template asset for Notice. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/ai/README.md` - Bootstrap template asset for Readme. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/ai/chatbot-intents.md` - Bootstrap template asset for Chatbot Intents. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/ai/llm_config.yaml` - Bootstrap template asset for LLM Config. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/distribution/README.md` - Bootstrap template asset for Readme. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/distribution/platforms/android/README.md` - Bootstrap template asset for Readme. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/distribution/platforms/ios/README.md` - Bootstrap template asset for Readme. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/distribution/platforms/linux/README.md` - Bootstrap template asset for Readme. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/distribution/platforms/macos/README.md` - Bootstrap template asset for Readme. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/distribution/platforms/windows/Install.ps1` - Bootstrap template asset for Install Ps1. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/distribution/platforms/windows/README.md` - Bootstrap template asset for Readme. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/docs/security/architecture.md` - Bootstrap template asset for Architecture. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/docs/security/backend-inventory.md` - Bootstrap template asset for Backend Inventory. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/docs/security/rollback.md` - Bootstrap template asset for Rollback. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/docs/security/validation.md` - Bootstrap template asset for Validation. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/mobile/README.md` - Bootstrap template asset for Readme. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/mobile/flutter/README.md` - Bootstrap template asset for Readme. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/mobile/flutter/android/app/src/main/AndroidManifest.xml` - Bootstrap template asset for Androidmanifest Xml. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/mobile/flutter/lib/main.dart` - Bootstrap template asset for Main Dart. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/mobile/flutter/pubspec.yaml` - Bootstrap template asset for Pubspec. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/ops/compose/compose.yml` - Bootstrap template asset for Compose. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/ops/env/.env.example` - Bootstrap template asset for Env. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/ops/install/README.md` - Bootstrap template asset for Readme. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/ops/install/install.sh` - Bootstrap template asset for Install. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/ops/install/lib/port_allocator.py` - Bootstrap template asset for Port Allocator Py. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/ops/install/lib/runtime-foundation.sh` - Bootstrap template asset for Runtime Foundation. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/ops/install/purge.sh` - Bootstrap template asset for Purge. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/ops/install/repair.sh` - Bootstrap template asset for Repair. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/ops/install/uninstall.sh` - Bootstrap template asset for Uninstall. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/ops/logging/README.md` - Bootstrap template asset for Readme. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/packaging/README.md` - Bootstrap template asset for Readme. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/packaging/__AIAST_DESKTOP_ID__.desktop` - Bootstrap template asset for Aiast Desktop Id Desktop. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/packaging/appimage.yml` - Bootstrap template asset for Appimage. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/packaging/flatpak-manifest.json` - Bootstrap template asset for Flatpak Manifest. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/packaging/signing/README.md` - Bootstrap template asset for Readme. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/packaging/snapcraft.yaml` - Bootstrap template asset for Snapcraft. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/registry/backend-assignments.yaml` - Bootstrap template asset for Backend Assignments. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/registry/port_assignments.yaml` - Bootstrap template asset for Port Assignments. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/registry/port_governance.yaml` - Bootstrap template asset for Port Governance. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/registry/ports.yaml` - Bootstrap template asset for Ports. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/tools/check-port-collisions.py` - Bootstrap template asset for Check Port Collisions Py. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/tools/port_registry_lib.py` - Bootstrap template asset for Port Registry Lib Py. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/tools/preflight_port_scan.py` - Bootstrap template asset for Preflight Port Scan Py. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/templates/runtime/tools/security-preflight.sh` - Bootstrap template asset for Security Preflight. Copied or rendered into repo-owned runtime or system surfaces during init, update, repair, or runtime-foundation generation.
- `bootstrap/track-semantic-changes.sh` - Classifies git diff changes as structural, contractual, cosmetic, or behavioral. Run when assessing the impact of recent changes.
- `bootstrap/uninstall-system.sh` - Removal flow for uninstalling the operating layer while leaving runtime code alone. Run only when intentionally removing AIAST from a repo.
- `bootstrap/update-template.sh` - Additive upgrade flow for refreshing an installed repo from a newer source template. Run when a repo already has AIAST and should be updated to a newer release.
- `bootstrap/upgrade-assistant.sh` - Interactive upgrade guide with version diff, breaking change warnings, and post-upgrade validation. Run when upgrading an installed repo to a newer AIAST version.
- `bootstrap/validate-instruction-layer.sh` - Validator for precedence, operating-profile, and prompt-emission surfaces. Run when instruction, adapter, or host-ingestion surfaces change.
- `bootstrap/validate-mcp-health.sh` - Bootstrap command for Validate MCP Health. Run when performing the named install, repair, validation, emission, or generation task.
- `bootstrap/validate-plugin.sh` - Validates a plugin manifest against the PLUGIN_CONTRACT schema and allowed hook points. Run when creating or verifying a plugin.
- `bootstrap/validate-system.sh` - Strict structural validator for required files and baseline portability. Run after meaningful system changes or before trusting an installed repo state.
- `bootstrap/verify-integrity.sh` - Hash generator and verifier for AIAST-managed files. Run when confirming or refreshing integrity state.
- `bootstrap/wizard.sh` - Interactive AIAST setup wizard with stack detection, profile configuration, and blueprint selection. Run for guided first-time setup of a new repo.
- `bootstrap/write-checkpoint.sh` - Bootstrap command for Write Checkpoint. Run when performing the named install, repair, validation, emission, or generation task.

### System Core

These files define the installable operating-system contracts, policies, guides, manifests, and indexes.

- `_system/.template-install.json` - Core operating-system reference for Template Install. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/.template-version` - Core operating-system reference for Template Version. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/ACCESSIBILITY_STANDARDS.md` - Core operating-system reference for Accessibility Standards. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/AGENT_DISCOVERY_MATRIX.md` - Matrix of which tools and hosts load which repo surfaces. Use when checking host coverage or adapter expectations.
- `_system/AGENT_INIT_CONVERGENCE.md` - Core operating-system reference for Agent Init Convergence. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/AGENT_INSTALLER_AND_HOST_VALIDATION_PROTOCOL.md` - Core operating-system reference for Agent Installer And Host Validation Protocol. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/AGENT_PERFORMANCE_GUIDE.md` - Model capability dimensions, task-to-model mapping, and multi-agent delegation guidance. Read when choosing which model to use for a specific task type.
- `_system/AGENT_ROLE_CATALOG.md` - Canonical role catalog and ownership model for delegated work. Read when selecting or defining agent roles.
- `_system/AGENT_SURFACE_TAXONOMY.md` - Core operating-system reference for Agent Surface Taxonomy. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/AI_RULES.md` - Core operating-system reference for AI Rules. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/API_DESIGN_STANDARDS.md` - Core operating-system reference for API Design Standards. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/ARCHITECTURE_DIAGRAM.md` - ASCII box diagrams of the three-layer model, loading flow, adapter pipeline, and validation chain. Read when understanding the system architecture or explaining it to others.
- `_system/AUTH_AND_ONBOARDING_PATTERNS.md` - Core operating-system reference for Auth And Onboarding Patterns. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/AUTH_RECOVERY_PROTOCOL.md` - Core operating-system reference for Auth Recovery Protocol. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/AUTONOMOUS_GUARDRAILS_PROTOCOL.md` - Core operating-system reference for Autonomous Guardrails Protocol. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/CAPABILITY_MATRIX.json` - Core operating-system reference for Capability Matrix. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/CHATBOT_GUIDE.md` - Core operating-system reference for Chatbot Guide. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/CHECKPOINT_PROTOCOL.md` - Core operating-system reference for Checkpoint Protocol. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/CODING_STANDARDS.md` - Core operating-system reference for Coding Standards. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/CONTEXT_BUDGET_STRATEGY.md` - Four-tier context budget model (A/B/C/D) keyed by model context window size. Read when selecting which files to load for a context-constrained model.
- `_system/CONTEXT_INDEX.md` - Map of the operating-system surfaces and where each type of truth lives. Read early when orienting to the system or locating the right file to update.
- `_system/CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md` - Core operating-system reference for Cross Platform Distribution And Installer Standard. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/CURSOR_AND_MULTI_HOST.md` - Core operating-system reference for Cursor And Multi Host. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/DEBUG_REPAIR_PLAYBOOK.md` - Core operating-system reference for Debug Repair Playbook. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/DELIVERY_GATES.md` - Core operating-system reference for Delivery Gates. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/DEPENDENCY_GOVERNANCE.md` - Core operating-system reference for Dependency Governance. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/DESIGN_EXCELLENCE_FRAMEWORK.md` - Core operating-system reference for Design Excellence Framework. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/ENVIRONMENT_VALIDATION_CONTRACT.md` - Scope and rules for environment-level checks (CLI tools, ports, env vars, disk space). Read when adding or adjusting environment validation behavior.
- `_system/EXECUTION_PROTOCOL.md` - How work should be executed, validated, and handed off. Read before starting or reshaping a meaningful execution slice.
- `_system/FAILURE_MODES_AND_RECOVERY.md` - Core operating-system reference for Failure Modes And Recovery. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/GIT_REMOTE_AND_SYNC_PROTOCOL.md` - Core operating-system reference for Git Remote And Sync Protocol. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/GOLDEN_EXAMPLES_POLICY.md` - Policy for using curated examples without copying donor-app truth. Read before drafting new system docs, prompts, or working-file structures.
- `_system/HALLUCINATION_DEFENSE_PROTOCOL.md` - Protocol for grounding claims in repo-local evidence. Use when confidence or claimed system state could drift from evidence.
- `_system/HANDOFF_PROTOCOL.md` - Core operating-system reference for Handoff Protocol. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/HOOK_AND_ORCHESTRATION_INDEX.md` - Core operating-system reference for Hook And Orchestration Index. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/HOST_ADAPTER_POLICY.md` - Policy for generated tool-entry and load-context adapter surfaces. Read when tool-specific entrypoints or overlays change.
- `_system/HOST_BUNDLE_CONTRACT.md` - Contract for self-contained bundles exported to external hosts. Read when a consumer cannot access repo-local paths directly.
- `_system/INSTALLATION_GUIDE.md` - Core operating-system reference for Installation Guide. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/INSTALLER_AND_UPGRADE_CONTRACT.md` - Core operating-system reference for Installer And Upgrade Contract. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/INSTRUCTION_CONFLICT_PLAYBOOK.md` - Core operating-system reference for Instruction Conflict Playbook. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md` - Conflict-resolution contract for repo-local, host-level, and adapter-level instructions. Read before trusting upstream orchestration over repo-local truth.
- `_system/INTEGRITY_MANIFEST.sha256` - Core operating-system reference for Integrity Manifest Sha256. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/KEY.md` - Exhaustive agent-facing key for every AIAST-managed file. Use when you need to understand the full system surface without guessing which files matter.
- `_system/LOAD_ORDER.md` - Recommended read order for loading the system efficiently. Use when context is limited or when a host needs a deterministic startup sequence.
- `_system/MASTER_SYSTEM_PROMPT.md` - Canonical shared operating prompt for the local system. Use when reasoning about the common behavioral contract across hosts.
- `_system/MCP_CONFIG.md` - Core operating-system reference for MCP Config. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/MEMORY_RULES.md` - Rules for what belongs in durable repo memory versus transient chat context. Use when deciding whether a fact should be persisted.
- `_system/MIGRATION_GUIDE.md` - Migration paths from no agent system, Cursor-only, custom CLAUDE.md, or other frameworks. Read when onboarding a repo that already has some agent governance.
- `_system/MOBILE_GUIDE.md` - Core operating-system reference for Mobile Guide. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/MODERN_UI_PATTERNS.md` - Core operating-system reference for Modern UI Patterns. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/MULTI_AGENT_COORDINATION.md` - Turn-taking and ownership rules for multi-agent work. Use when planning delegated or parallel execution.
- `_system/OBSERVABILITY_STANDARDS.md` - Core operating-system reference for Observability Standards. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/OPERATOR_PROMPTING_PLAYBOOK.md` - Core operating-system reference for Operator Prompting Playbook. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/PACKAGING_GUIDE.md` - Core operating-system reference for Packaging Guide. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/PERFORMANCE_BUDGET.md` - Core operating-system reference for Performance Budget. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/PLUGIN_CONTRACT.md` - Contract for optional AIAST extensions with 12 hook points, manifest schema, and lifecycle. Read when creating, validating, or understanding plugins.
- `_system/PROJECT_PROFILE.md` - Repo-specific operational truth about languages, structure, packaging, and validation commands. Read early in every session and update when project reality becomes clearer.
- `_system/PROJECT_RULES.md` - Repo-wide non-negotiable working rules. Read whenever the task could affect boundaries, truthfulness, or workflow rules.
- `_system/PROMPTS_INDEX.md` - Index of prompt templates and prompt packs. Use when assembling or auditing prompt surfaces.
- `_system/PROMPT_BACKEND_POLICY.md` - Core operating-system reference for Prompt Backend Policy. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/PROMPT_DOCKER_NETWORK_POLICY.md` - Core operating-system reference for Prompt Docker Network Policy. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/PROMPT_EFFECTIVENESS_TRACKING.md` - Protocol for measuring which prompt packs succeed or fail per model and task type. Read when recording or analyzing prompt effectiveness data.
- `_system/PROMPT_EMISSION_CONTRACT.md` - Rules for emitting prompts for external tools or hosts. Read when prompt-generation or host-export behavior changes.
- `_system/PROMPT_SECURITY_BASELINE.md` - Core operating-system reference for Prompt Security Baseline. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/PROMPT_SYSTEM_BUILD_STANDARD.md` - Core operating-system reference for Prompt System Build Standard. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/PROVENANCE_AND_EVIDENCE.md` - Core operating-system reference for Provenance And Evidence. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/QUICKSTART.md` - One-page onboarding guide for new AIAST users. Read when first encountering the system or directing someone to the fastest start path.
- `_system/README.md` - Overview of what belongs inside the local operating-system directory. Read during first orientation to the `_system/` layer.
- `_system/READ_BUNDLES.md` - Core operating-system reference for Read Bundles. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/RELEASE_READINESS_PROTOCOL.md` - Core operating-system reference for Release Readiness Protocol. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/REPO_BOUNDARY_AND_BACKUP.md` - Core operating-system reference for Repo Boundary And Backup. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/REPO_CONVENTIONS.md` - Core operating-system reference for Repo Conventions. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/REPO_OPERATING_PROFILE.md` - Compact machine-friendly summary of the repo operating model. Use when a host needs fast repo ingestion without reading the entire system.
- `_system/REQUEST_ALIGNMENT_PROTOCOL.md` - Core operating-system reference for Request Alignment Protocol. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/SECURITY_BASELINE.md` - Core operating-system reference for Security Baseline. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/SECURITY_HARDENING_CONTRACT.md` - Core operating-system reference for Security Hardening Contract. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/SECURITY_REDACTION_AND_AUDIT.md` - Core operating-system reference for Security Redaction And Audit. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/SELF_HEALING_BOUNDARY.md` - Core operating-system reference for Self Healing Boundary. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/SKILLS_INDEX.md` - Index of reusable skills and their intended roles. Use when deciding whether a capability should live as a skill.
- `_system/STANDARDS_CONFLICT_RESOLUTION.md` - Core operating-system reference for Standards Conflict Resolution. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/SUB_AGENT_HOST_DELEGATION.md` - Core operating-system reference for Sub Agent Host Delegation. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/SYSTEM_AWARENESS_PROTOCOL.md` - Contract for how AIAST tracks and validates its own managed surfaces. Read when changing registries, file maps, or self-awareness checks.
- `_system/SYSTEM_EVOLUTION_POLICY.md` - Core operating-system reference for System Evolution Policy. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/SYSTEM_ORCHESTRATION_GUIDE.md` - Meta-map: how core surfaces connect, recommended review/validation order, evolution and conflict pointers. Read once when onboarding, consolidating systems, or when you need a single checklist instead of scattered entry points.
- `_system/SYSTEM_REGISTRY.json` - Machine-readable inventory of AIAST-managed files. Use when tooling needs deterministic file coverage instead of prose guidance.
- `_system/TEMPLATE_CHANGE_IMPACT_POLICY.md` - Core operating-system reference for Template Change Impact Policy. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/TEMPLATE_NEUTRALITY_POLICY.md` - Rules that keep the source template reusable across future repos. Use when changing installable defaults or working-file seed content.
- `_system/THREAT_MODEL_TEMPLATE.md` - Core operating-system reference for Threat Model Template. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/TROUBLESHOOTING.md` - Symptom-based FAQ for common AIAST issues and their fixes. Read when something is broken and you need a quick diagnosis path.
- `_system/UPGRADE_AND_DRIFT_POLICY.md` - Core operating-system reference for Upgrade And Drift Policy. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/VALIDATION_GATES.md` - Core operating-system reference for Validation Gates. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/VERSION_SENSITIVE_RESEARCH_PROTOCOL.md` - Core operating-system reference for Version Sensitive Research Protocol. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/WORKING_FILES_GUIDE.md` - Guide to the role of each working-state file. Read when deciding where new project truth or progress belongs.
- `_system/agent-performance-profiles.json` - Machine-readable ratings for 19 model families across quality, planning, review, speed, and cost. Use when tooling needs programmatic model selection based on capability.
- `_system/aiaast-capabilities.json` - Core operating-system reference for AIAST Capabilities. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/automation/.gitignore` - Core operating-system reference for Gitignore. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/automation/README.md` - Core operating-system reference for Readme. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/checkpoints/README.md` - Core operating-system reference for Readme. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/checkpoints/history/.gitkeep` - Core operating-system reference for Gitkeep. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/context-budget-profiles.json` - Machine-readable tier assignments for 21 model families with context token counts. Use when emit-tiered-context.sh needs to resolve a model to a tier.
- `_system/design-system/THEME_GOVERNANCE.md` - Core operating-system reference for Theme Governance. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/golden-examples/PATTERN_INDEX.md` - Golden-example asset for Pattern Index. Use when auditing or refreshing the curated example pack.
- `_system/golden-examples/README.md` - Golden-example asset for Readme. Use when auditing or refreshing the curated example pack.
- `_system/golden-examples/golden-example-manifest.json` - Golden-example asset for Golden Example Manifest. Use when auditing or refreshing the curated example pack.
- `_system/golden-examples/patterns/CODE_SNIPPET_EXAMPLES.md` - Neutral pattern guide for Code Snippet Examples. Use when drafting or revising the same kind of system surface without copying donor-app facts.
- `_system/golden-examples/patterns/CONTINUITY_AND_HANDOFF.md` - Neutral pattern guide for Continuity And Handoff. Use when drafting or revising the same kind of system surface without copying donor-app facts.
- `_system/golden-examples/patterns/DATA_PIPELINE_AND_ML.md` - Neutral pattern guide for Data Pipeline And Ml. Use when drafting or revising the same kind of system surface without copying donor-app facts.
- `_system/golden-examples/patterns/ERROR_HANDLING_PATTERNS.md` - Neutral pattern guide for Error Handling Patterns. Use when drafting or revising the same kind of system surface without copying donor-app facts.
- `_system/golden-examples/patterns/EVENT_DRIVEN_AND_CQRS.md` - Neutral pattern guide for Event Driven And Cqrs. Use when drafting or revising the same kind of system surface without copying donor-app facts.
- `_system/golden-examples/patterns/GOVERNANCE_AND_PROMPTING.md` - Neutral pattern guide for Governance And Prompting. Use when drafting or revising the same kind of system surface without copying donor-app facts.
- `_system/golden-examples/patterns/MICROSERVICES_ARCHITECTURE.md` - Neutral pattern guide for Microservices Architecture. Use when drafting or revising the same kind of system surface without copying donor-app facts.
- `_system/golden-examples/patterns/MULTI_AGENT_AND_MCP.md` - Neutral pattern guide for Multi Agent And MCP. Use when drafting or revising the same kind of system surface without copying donor-app facts.
- `_system/golden-examples/patterns/PLATFORM_SURFACES.md` - Neutral pattern guide for Platform Surfaces. Use when drafting or revising the same kind of system surface without copying donor-app facts.
- `_system/golden-examples/patterns/REALTIME_COLLABORATION.md` - Neutral pattern guide for Realtime Collaboration. Use when drafting or revising the same kind of system surface without copying donor-app facts.
- `_system/golden-examples/patterns/SERVERLESS_AND_EDGE.md` - Neutral pattern guide for Serverless And Edge. Use when drafting or revising the same kind of system surface without copying donor-app facts.
- `_system/golden-examples/patterns/TESTING_PATTERNS.md` - Neutral pattern guide for Testing Patterns. Use when drafting or revising the same kind of system surface without copying donor-app facts.
- `_system/golden-examples/patterns/VALIDATION_AND_RELEASE.md` - Neutral pattern guide for Validation And Release. Use when drafting or revising the same kind of system surface without copying donor-app facts.
- `_system/golden-examples/working-files/PLAN_EXAMPLE.md` - Quality-bar working-file example for Plan Example. Use when shaping the corresponding repo-local working file.
- `_system/golden-examples/working-files/PROJECT_PROFILE_EXAMPLE.md` - Quality-bar working-file example for Project Profile Example. Use when shaping the corresponding repo-local working file.
- `_system/golden-examples/working-files/WHERE_LEFT_OFF_EXAMPLE.md` - Quality-bar working-file example for Where Left Off Example. Use when shaping the corresponding repo-local working file.
- `_system/health-history.json` - Append-only log of system-doctor results for trend tracking (50-entry rotation). Read by report-health-trends.sh; written by system-doctor.sh --record.
- `_system/host-adapter-manifest.json` - Canonical machine-readable source for generated host adapters. Edit only when adapter inputs change, then regenerate the adapters.
- `_system/instruction-precedence.json` - Machine-readable instruction-precedence manifest. Use when validating or exporting precedence behavior programmatically.
- `_system/llm_config.yaml.example` - Core operating-system reference for LLM Config. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/ports/PORT_POLICY.md` - Core operating-system reference for Port Policy. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/ports/default_port_matrix.yaml` - Core operating-system reference for Default Port Matrix. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/ports/templates/README.md` - Core operating-system reference for Readme. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/ports/templates/compose-loopback-snippet.yml` - Core operating-system reference for Compose Loopback Snippet. Load when the task touches that named contract, policy, guide, or manifest.
- `_system/repo-operating-profile.json` - Core operating-system reference for Repo Operating Profile. Load when the task touches that named contract, policy, guide, or manifest.

### Durable Context

These files hold long-lived project memory and integration state.

- `_system/context/ARCHITECTURAL_INVARIANTS.md` - Durable context record for Architectural Invariants. Read during resume and update when the underlying project truth changes.
- `_system/context/ASSUMPTIONS.md` - Durable context record for Assumptions. Read during resume and update when the underlying project truth changes.
- `_system/context/CURRENT_STATUS.md` - Durable context record for Current Status. Read during resume and update when the underlying project truth changes.
- `_system/context/DECISIONS.md` - Durable context record for Decisions. Read during resume and update when the underlying project truth changes.
- `_system/context/INTEGRATION_SURFACES.md` - Durable context record for Integration Surfaces. Read during resume and update when the underlying project truth changes.
- `_system/context/MEMORY.md` - Durable context record for Memory. Read during resume and update when the underlying project truth changes.
- `_system/context/OPEN_QUESTIONS.md` - Durable context record for Open Questions. Read during resume and update when the underlying project truth changes.
- `_system/context/QUALITY_DEBT.md` - Durable context record for Quality Debt. Read during resume and update when the underlying project truth changes.
- `_system/context/README.md` - Durable context record for Readme. Read during resume and update when the underlying project truth changes.
- `_system/context/prompt-usage-log.json` - Durable context record for Prompt Usage Log. Read during resume and update when the underlying project truth changes.

### Review Playbooks

These files provide structured review passes for major quality domains.

- `_system/review-playbooks/ACCESSIBILITY_REVIEW_PLAYBOOK.md` - Structured review playbook for Accessibility Review Playbook. Run it when performing that named review pass.
- `_system/review-playbooks/ARCHITECTURE_REVIEW_PLAYBOOK.md` - Structured review playbook for Architecture Review Playbook. Run it when performing that named review pass.
- `_system/review-playbooks/CODE_QUALITY_REVIEW_PLAYBOOK.md` - Structured review playbook for Code Quality Review Playbook. Run it when performing that named review pass.
- `_system/review-playbooks/DEPENDENCY_REVIEW_PLAYBOOK.md` - Structured review playbook for Dependency Review Playbook. Run it when performing that named review pass.
- `_system/review-playbooks/PERFORMANCE_REVIEW_PLAYBOOK.md` - Structured review playbook for Performance Review Playbook. Run it when performing that named review pass.
- `_system/review-playbooks/SECURITY_HARDENING_REVIEW_PLAYBOOK.md` - Structured review playbook for Security Hardening Review Playbook. Run it when performing that named review pass.
- `_system/review-playbooks/SECURITY_REVIEW_PLAYBOOK.md` - Structured review playbook for Security Review Playbook. Run it when performing that named review pass.
- `_system/review-playbooks/UI_UX_REVIEW_PLAYBOOK.md` - Structured review playbook for UI UX Review Playbook. Run it when performing that named review pass.

### Prompting Assets

These files support prompt emission, reusable prompt templates, and prompt packs.

- `_system/prompt-packs/M0_FOUNDATION.md` - Prompt-pack asset for M0 Foundation. Load when generating prompts for the matching workflow or role.
- `_system/prompt-packs/M10_GREENFIELD_BOOTSTRAP.md` - Prompt-pack asset for M10 Greenfield Bootstrap. Load when generating prompts for the matching workflow or role.
- `_system/prompt-packs/M11_MATURE_REPO_RETROFIT.md` - Prompt-pack asset for M11 Mature Repo Retrofit. Load when generating prompts for the matching workflow or role.
- `_system/prompt-packs/M12_PERFORMANCE_OPTIMIZATION.md` - Prompt-pack asset for M12 Performance Optimization. Load when generating prompts for the matching workflow or role.
- `_system/prompt-packs/M13_ACCESSIBILITY_AND_INCLUSION.md` - Prompt-pack asset for M13 Accessibility And Inclusion. Load when generating prompts for the matching workflow or role.
- `_system/prompt-packs/M14_SECURITY_HARDENING.md` - Prompt-pack asset for M14 Security Hardening. Load when generating prompts for the matching workflow or role.
- `_system/prompt-packs/M15_WHOLE_REPO_ANALYSIS.md` - Prompt-pack asset for M15 Whole Repo Analysis. Load when generating prompts for the matching workflow or role.
- `_system/prompt-packs/M16_PLATFORM_PRODUCT_EXPANSION.md` - Prompt-pack asset for M16 Platform Product Expansion. Load when generating prompts for the matching workflow or role.
- `_system/prompt-packs/M1_FEATURE_DELIVERY.md` - Prompt-pack asset for M1 Feature Delivery. Load when generating prompts for the matching workflow or role.
- `_system/prompt-packs/M2_DEBUG_AND_STABILIZE.md` - Prompt-pack asset for M2 Debug And Stabilize. Load when generating prompts for the matching workflow or role.
- `_system/prompt-packs/M3_REVIEW_AND_RELEASE.md` - Prompt-pack asset for M3 Review And Release. Load when generating prompts for the matching workflow or role.
- `_system/prompt-packs/M4_ARCHITECTURE_EXPANSION.md` - Prompt-pack asset for M4 Architecture Expansion. Load when generating prompts for the matching workflow or role.
- `_system/prompt-packs/M5_MIGRATION_AND_REFACTOR.md` - Prompt-pack asset for M5 Migration And Refactor. Load when generating prompts for the matching workflow or role.
- `_system/prompt-packs/M6_INSTALL_AND_DISTRIBUTION.md` - Prompt-pack asset for M6 Install And Distribution. Load when generating prompts for the matching workflow or role.
- `_system/prompt-packs/M7_DESIGN_EXCELLENCE.md` - Prompt-pack asset for M7 Design Excellence. Load when generating prompts for the matching workflow or role.
- `_system/prompt-packs/M8_SECURITY_AND_COMPLIANCE.md` - Prompt-pack asset for M8 Security And Compliance. Load when generating prompts for the matching workflow or role.
- `_system/prompt-packs/M9_MULTI_AGENT_CONTINUITY.md` - Prompt-pack asset for M9 Multi Agent Continuity. Load when generating prompts for the matching workflow or role.
- `_system/prompt-templates/architecture_prompt_template.md` - Prompt template for Architecture Prompt Template. Use when assembling a task-specific prompt from reusable building blocks.
- `_system/prompt-templates/developer_prompt_template.md` - Prompt template for Developer Prompt Template. Use when assembling a task-specific prompt from reusable building blocks.
- `_system/prompt-templates/optimization_prompt_template.md` - Prompt template for Optimization Prompt Template. Use when assembling a task-specific prompt from reusable building blocks.
- `_system/prompt-templates/repair_prompt_template.md` - Prompt template for Repair Prompt Template. Use when assembling a task-specific prompt from reusable building blocks.
- `_system/prompt-templates/review_prompt_template.md` - Prompt template for Review Prompt Template. Use when assembling a task-specific prompt from reusable building blocks.
- `_system/prompt-templates/system_prompt_template.md` - Prompt template for System Prompt Template. Use when assembling a task-specific prompt from reusable building blocks.
- `_system/prompt-templates/user_prompt_template.md` - Prompt template for User Prompt Template. Use when assembling a task-specific prompt from reusable building blocks.

### Starter Blueprints

These files describe the canonical starter shapes used during greenfield repo setup.

- `_system/starter-blueprints/BACKGROUND_WORKER.md` - Starter blueprint contract for Background Worker. Read when choosing, recommending, or applying that build shape.
- `_system/starter-blueprints/DATABASE_MIGRATIONS.md` - Starter blueprint contract for Database Migrations. Read when choosing, recommending, or applying that build shape.
- `_system/starter-blueprints/FASTAPI_API.md` - Starter blueprint contract for Fastapi API. Read when choosing, recommending, or applying that build shape.
- `_system/starter-blueprints/FLUTTER_ANDROID_CLIENT.md` - Starter blueprint contract for Flutter Android Client. Read when choosing, recommending, or applying that build shape.
- `_system/starter-blueprints/GO_SERVICE.md` - Starter blueprint contract for Go Service. Read when choosing, recommending, or applying that build shape.
- `_system/starter-blueprints/GRAPHQL_API.md` - Starter blueprint contract for Graphql API. Read when choosing, recommending, or applying that build shape.
- `_system/starter-blueprints/GRPC_SERVICE.md` - Starter blueprint contract for Grpc Service. Read when choosing, recommending, or applying that build shape.
- `_system/starter-blueprints/NEXT_JS_FULLSTACK.md` - Starter blueprint contract for Next Js Fullstack. Read when choosing, recommending, or applying that build shape.
- `_system/starter-blueprints/PYTHON_CLI_TOOL.md` - Starter blueprint contract for Python CLI Tool. Read when choosing, recommending, or applying that build shape.
- `_system/starter-blueprints/REACT_VITE_TYPESCRIPT.md` - Starter blueprint contract for React Vite Typescript. Read when choosing, recommending, or applying that build shape.
- `_system/starter-blueprints/README.md` - Starter blueprint contract for Readme. Read when choosing, recommending, or applying that build shape.
- `_system/starter-blueprints/RUST_CLI_TOOL.md` - Starter blueprint contract for Rust CLI Tool. Read when choosing, recommending, or applying that build shape.
- `_system/starter-blueprints/STATIC_FRONTEND.md` - Starter blueprint contract for Static Frontend. Read when choosing, recommending, or applying that build shape.
- `_system/starter-blueprints/TAURI_DESKTOP.md` - Starter blueprint contract for Tauri Desktop. Read when choosing, recommending, or applying that build shape.
- `_system/starter-blueprints/UNIVERSAL_APP_PLATFORM.md` - Starter blueprint contract for Universal App Platform. Read when choosing, recommending, or applying that build shape.

### MCP Surfaces

These files describe optional MCP usage, cataloging, and fallback behavior.

- `_system/mcp/MCP_FAILURE_FALLBACKS.md` - MCP reference for MCP Failure Fallbacks. Read when selecting, cataloging, or recovering from MCP integrations.
- `_system/mcp/MCP_SELECTION_POLICY.md` - MCP reference for MCP Selection Policy. Read when selecting, cataloging, or recovering from MCP integrations.
- `_system/mcp/MCP_SERVER_CATALOG.md` - MCP reference for MCP Server Catalog. Read when selecting, cataloging, or recovering from MCP integrations.
- `_system/mcp/MCP_SERVER_CATALOG_TEMPLATE.md` - MCP reference for MCP Server Catalog Template. Read when selecting, cataloging, or recovering from MCP integrations.
- `_system/mcp/MCP_SURVIVAL_PLAYBOOK.md` - MCP reference for MCP Survival Playbook. Read when selecting, cataloging, or recovering from MCP integrations.
- `_system/mcp/README.md` - MCP reference for Readme. Read when selecting, cataloging, or recovering from MCP integrations.
- `_system/mcp/servers.codex.example.toml` - MCP reference for Servers Codex Example Toml. Read when selecting, cataloging, or recovering from MCP integrations.
- `_system/mcp/servers.cursor.example.json` - MCP reference for Servers Cursor Example. Read when selecting, cataloging, or recovering from MCP integrations.

### CI Surfaces

These files are reusable automation examples for CI pipelines.

- `_system/ci/README.md` - CI example for Readme. Use when wiring repo automation or comparing CI layouts.
- `_system/ci/github-actions/android.yml.example` - CI example for Android. Use when wiring repo automation or comparing CI layouts.
- `_system/ci/github-actions/ci.yml.example` - CI example for CI. Use when wiring repo automation or comparing CI layouts.
- `_system/ci/github-actions/linux-packaging.yml.example` - CI example for Linux Packaging. Use when wiring repo automation or comparing CI layouts.
- `_system/ci/github-actions/release.yml.example` - CI example for Release. Use when wiring repo automation or comparing CI layouts.
- `_system/ci/gitlab-ci.yml.example` - CI example for Gitlab CI. Use when wiring repo automation or comparing CI layouts.

### Packaging Surfaces

These files describe packaging policy and provide reusable packaging templates.

- `_system/packaging/README.md` - Packaging reference for Readme. Read when shaping release and distribution surfaces.
- `_system/packaging/node-and-desktop-packaging.md` - Packaging reference for Node And Desktop Packaging. Read when shaping release and distribution surfaces.
- `_system/packaging/python-packaging.md` - Packaging reference for Python Packaging. Read when shaping release and distribution surfaces.
- `_system/packaging/rust-and-go-packaging.md` - Packaging reference for Rust And Go Packaging. Read when shaping release and distribution surfaces.
- `_system/packaging/templates/appimage-builder.yml.example` - Reusable packaging template for Appimage Builder. Use when generating or validating the matching packaging target.
- `_system/packaging/templates/appimage.yml.example` - Reusable packaging template for Appimage. Use when generating or validating the matching packaging target.
- `_system/packaging/templates/flatpak-manifest.json.example` - Reusable packaging template for Flatpak Manifest. Use when generating or validating the matching packaging target.
- `_system/packaging/templates/flatpak.yaml.example` - Reusable packaging template for Flatpak. Use when generating or validating the matching packaging target.
- `_system/packaging/templates/snapcraft.yaml.example` - Reusable packaging template for Snapcraft. Use when generating or validating the matching packaging target.
- `packaging/README.md` - Managed AIAST surface for Readme. Use it when the task clearly touches the surface named by this file.
- `packaging/appimage.yml` - Managed AIAST surface for Appimage. Use it when the task clearly touches the surface named by this file.
- `packaging/flatpak-manifest.json` - Managed AIAST surface for Flatpak Manifest. Use it when the task clearly touches the surface named by this file.
- `packaging/io.aiaast.budget.beacon.desktop` - Managed AIAST surface for Io AIAST Budget Beacon Desktop. Use it when the task clearly touches the surface named by this file.
- `packaging/signing/README.md` - Managed AIAST surface for Readme. Use it when the task clearly touches the surface named by this file.
- `packaging/snapcraft.yaml` - Managed AIAST surface for Snapcraft. Use it when the task clearly touches the surface named by this file.

### Plugin Surfaces

These files define optional AIAST extension hooks.

- `_system/plugins/README.md` - Plugin extension surface for Readme. Read when adding or validating optional AIAST extensions.
- `_system/plugins/ci-integration/README.md` - Plugin extension surface for Readme. Read when adding or validating optional AIAST extensions.
- `_system/plugins/ci-integration/plugin.json` - Plugin extension surface for Plugin. Read when adding or validating optional AIAST extensions.
- `_system/plugins/ci-integration/run.sh` - Plugin extension surface for Run. Read when adding or validating optional AIAST extensions.
- `_system/plugins/observability-setup/README.md` - Plugin extension surface for Readme. Read when adding or validating optional AIAST extensions.
- `_system/plugins/observability-setup/plugin.json` - Plugin extension surface for Plugin. Read when adding or validating optional AIAST extensions.
- `_system/plugins/observability-setup/run.sh` - Plugin extension surface for Run. Read when adding or validating optional AIAST extensions.
- `_system/plugins/security-scan/README.md` - Plugin extension surface for Readme. Read when adding or validating optional AIAST extensions.
- `_system/plugins/security-scan/plugin.json` - Plugin extension surface for Plugin. Read when adding or validating optional AIAST extensions.
- `_system/plugins/security-scan/run.sh` - Plugin extension surface for Run. Read when adding or validating optional AIAST extensions.

### Systemd Surfaces

These files provide hardened systemd references and examples.

- `_system/systemd/README.md` - Systemd reference for Readme. Use when generating or validating hardened service or timer units.
- `_system/systemd/http-service.example.service` - Systemd reference for Http Service Example. Use when generating or validating hardened service or timer units.
- `_system/systemd/scheduled-task.example.service` - Systemd reference for Scheduled Task Example. Use when generating or validating hardened service or timer units.
- `_system/systemd/scheduled-task.example.timer` - Systemd reference for Scheduled Task Example. Use when generating or validating hardened service or timer units.
- `_system/systemd/worker.example.service` - Systemd reference for Worker Example. Use when generating or validating hardened service or timer units.

### Cursor Agent Roles

These files define Cursor-specific delegated agent role prompts.

- `.cursor/agents/README.md` - Cursor delegated-agent prompt for Readme. Used when the named Cursor agent role is invoked.
- `.cursor/agents/architecture.md` - Cursor delegated-agent prompt for Architecture. Used when the named Cursor agent role is invoked.
- `.cursor/agents/composer-lead.md` - Cursor delegated-agent prompt for Composer Lead. Used when the named Cursor agent role is invoked.
- `.cursor/agents/context-curator.md` - Cursor delegated-agent prompt for Context Curator. Used when the named Cursor agent role is invoked.
- `.cursor/agents/design-reviewer.md` - Cursor delegated-agent prompt for Design Reviewer. Used when the named Cursor agent role is invoked.
- `.cursor/agents/github-ops.md` - Cursor delegated-agent prompt for Github Ops. Used when the named Cursor agent role is invoked.
- `.cursor/agents/implementation-worker.md` - Cursor delegated-agent prompt for Implementation Worker. Used when the named Cursor agent role is invoked.
- `.cursor/agents/orchestrator.md` - Cursor delegated-agent prompt for Orchestrator. Used when the named Cursor agent role is invoked.
- `.cursor/agents/release-manager.md` - Cursor delegated-agent prompt for Release Manager. Used when the named Cursor agent role is invoked.
- `.cursor/agents/security-reviewer.md` - Cursor delegated-agent prompt for Security Reviewer. Used when the named Cursor agent role is invoked.
- `.cursor/agents/validator.md` - Cursor delegated-agent prompt for Validator. Used when the named Cursor agent role is invoked.

### Cursor Commands

These files define Cursor slash-command prompts and guided workflows.

- `.cursor/commands/accessibility-review.md` - Cursor command surface for Accessibility Review. Used when invoking that named Cursor command.
- `.cursor/commands/architecture-review.md` - Cursor command surface for Architecture Review. Used when invoking that named Cursor command.
- `.cursor/commands/checkpoint.md` - Cursor command surface for Checkpoint. Used when invoking that named Cursor command.
- `.cursor/commands/code-quality-review.md` - Cursor command surface for Code Quality Review. Used when invoking that named Cursor command.
- `.cursor/commands/code-review.md` - Cursor command surface for Code Review. Used when invoking that named Cursor command.
- `.cursor/commands/composer-session.md` - Cursor command surface for Composer Session. Used when invoking that named Cursor command.
- `.cursor/commands/compress-context.md` - Cursor command surface for Compress Context. Used when invoking that named Cursor command.
- `.cursor/commands/concise-session.md` - Cursor command surface for Concise Session. Used when invoking that named Cursor command.
- `.cursor/commands/debug.md` - Cursor command surface for Debug. Used when invoking that named Cursor command.
- `.cursor/commands/dependency-review.md` - Cursor command surface for Dependency Review. Used when invoking that named Cursor command.
- `.cursor/commands/design-review.md` - Cursor command surface for Design Review. Used when invoking that named Cursor command.
- `.cursor/commands/github-session.md` - Cursor command surface for Github Session. Used when invoking that named Cursor command.
- `.cursor/commands/load-context.md` - Cursor command surface for Load Context. Used when invoking that named Cursor command.
- `.cursor/commands/performance-review.md` - Cursor command surface for Performance Review. Used when invoking that named Cursor command.
- `.cursor/commands/release-readiness.md` - Cursor command surface for Release Readiness. Used when invoking that named Cursor command.
- `.cursor/commands/session-start.md` - Cursor command surface for Session Start. Used when invoking that named Cursor command.
- `.cursor/commands/verify.md` - Cursor command surface for Verify. Used when invoking that named Cursor command.

### Cursor Rules

These files are auto-loaded Cursor rule overlays.

- `.cursor/rules/00-anti-drift-ssot.mdc` - Cursor rule overlay for 00 Anti Drift Ssot. Auto-loaded by Cursor to reinforce repo-local behavior.
- `.cursor/rules/00-context-load.mdc` - Cursor rule overlay for 00 Context Load. Auto-loaded by Cursor to reinforce repo-local behavior.
- `.cursor/rules/10-project-boundaries.mdc` - Cursor rule overlay for 10 Project Boundaries. Auto-loaded by Cursor to reinforce repo-local behavior.
- `.cursor/rules/20-multi-agent-awareness.mdc` - Cursor rule overlay for 20 Multi Agent Awareness. Auto-loaded by Cursor to reinforce repo-local behavior.
- `.cursor/rules/30-validation-gate.mdc` - Cursor rule overlay for 30 Validation Gate. Auto-loaded by Cursor to reinforce repo-local behavior.
- `.cursor/rules/40-mcp-and-tooling.mdc` - Cursor rule overlay for 40 MCP And Tooling. Auto-loaded by Cursor to reinforce repo-local behavior.
- `.cursor/rules/50-working-files.mdc` - Cursor rule overlay for 50 Working Files. Auto-loaded by Cursor to reinforce repo-local behavior.
- `.cursor/rules/60-composer-orchestration.mdc` - Cursor rule overlay for 60 Composer Orchestration. Auto-loaded by Cursor to reinforce repo-local behavior.
- `.cursor/rules/IDE_HOST_CURSOR_WINDSURF.mdc` - Cursor rule overlay for Ide Host Cursor Windsurf. Auto-loaded by Cursor to reinforce repo-local behavior.

### Cursor Skills

These files back Cursor skill surfaces and skill-local commands.

- `.cursor/skills/accessibility-review/SKILL.md` - Cursor skill asset for Skill. Used when the corresponding Cursor skill is loaded.
- `.cursor/skills/architecture-review/SKILL.md` - Cursor skill asset for Skill. Used when the corresponding Cursor skill is loaded.
- `.cursor/skills/checkpoint-handoff/SKILL.md` - Cursor skill asset for Skill. Used when the corresponding Cursor skill is loaded.
- `.cursor/skills/code-quality-review/SKILL.md` - Cursor skill asset for Skill. Used when the corresponding Cursor skill is loaded.
- `.cursor/skills/code-review/SKILL.md` - Cursor skill asset for Skill. Used when the corresponding Cursor skill is loaded.
- `.cursor/skills/compress-context-input/SKILL.md` - Cursor skill asset for Skill. Used when the corresponding Cursor skill is loaded.
- `.cursor/skills/concise-communication/SKILL.md` - Cursor skill asset for Skill. Used when the corresponding Cursor skill is loaded.
- `.cursor/skills/debug-playbook/SKILL.md` - Cursor skill asset for Skill. Used when the corresponding Cursor skill is loaded.
- `.cursor/skills/dependency-review/SKILL.md` - Cursor skill asset for Skill. Used when the corresponding Cursor skill is loaded.
- `.cursor/skills/design-review/SKILL.md` - Cursor skill asset for Skill. Used when the corresponding Cursor skill is loaded.
- `.cursor/skills/load-context/SKILL.md` - Cursor skill asset for Skill. Used when the corresponding Cursor skill is loaded.
- `.cursor/skills/mcp-config/SKILL.md` - Cursor skill asset for Skill. Used when the corresponding Cursor skill is loaded.
- `.cursor/skills/performance-review/SKILL.md` - Cursor skill asset for Skill. Used when the corresponding Cursor skill is loaded.
- `.cursor/skills/prompt-pack-generator/SKILL.md` - Cursor skill asset for Skill. Used when the corresponding Cursor skill is loaded.
- `.cursor/skills/release-readiness/SKILL.md` - Cursor skill asset for Skill. Used when the corresponding Cursor skill is loaded.
- `.cursor/skills/verify-gate/SKILL.md` - Cursor skill asset for Skill. Used when the corresponding Cursor skill is loaded.

### Cursor Overlays

These files are supporting Cursor-specific overlays that do not fit the narrower agent, command, rule, or skill buckets.

- `.cursor/README.md` - Cursor overlay surface for Readme. Read or regenerate when Cursor-specific integration surfaces change.
- `.cursor/mcp.json` - Cursor overlay surface for MCP. Read or regenerate when Cursor-specific integration surfaces change.

### Copilot Overlay

These files provide repo-local guidance to GitHub Copilot.

- `.github/ISSUE_TEMPLATE/bug_report.md` - GitHub Copilot overlay for Bug Report. Used when Copilot loads repo-local instructions.
- `.github/ISSUE_TEMPLATE/config.yml` - GitHub Copilot overlay for Config. Used when Copilot loads repo-local instructions.
- `.github/ISSUE_TEMPLATE/feature_request.md` - GitHub Copilot overlay for Feature Request. Used when Copilot loads repo-local instructions.
- `.github/pull_request_template.md` - GitHub Copilot overlay for Pull Request Template. Used when Copilot loads repo-local instructions.

### Unclassified

These files are managed but do not currently fit a more specific category.

- `.credits-hidden` - Managed AIAST surface for Credits Hidden. Use it when the task clearly touches the surface named by this file.
- `LICENSE` - Managed AIAST surface for License. Use it when the task clearly touches the surface named by this file.
- `NOTICE` - Managed AIAST surface for Notice. Use it when the task clearly touches the surface named by this file.
- `distribution/README.md` - Managed AIAST surface for Readme. Use it when the task clearly touches the surface named by this file.
- `distribution/platforms/android/README.md` - Managed AIAST surface for Readme. Use it when the task clearly touches the surface named by this file.
- `distribution/platforms/ios/README.md` - Managed AIAST surface for Readme. Use it when the task clearly touches the surface named by this file.
- `distribution/platforms/linux/README.md` - Managed AIAST surface for Readme. Use it when the task clearly touches the surface named by this file.
- `distribution/platforms/macos/README.md` - Managed AIAST surface for Readme. Use it when the task clearly touches the surface named by this file.
- `distribution/platforms/windows/Install.ps1` - Managed AIAST surface for Install Ps1. Use it when the task clearly touches the surface named by this file.
- `distribution/platforms/windows/README.md` - Managed AIAST surface for Readme. Use it when the task clearly touches the surface named by this file.
- `docs/ARCHITECTURE.md` - Managed AIAST surface for Architecture. Use it when the task clearly touches the surface named by this file.
- `docs/CONTEXT_COMPRESS_PILOT.md` - Managed AIAST surface for Context Compress Pilot. Use it when the task clearly touches the surface named by this file.
- `docs/DATA_MODEL.md` - Managed AIAST surface for Data Model. Use it when the task clearly touches the surface named by this file.
- `docs/NFR.md` - Managed AIAST surface for Nfr. Use it when the task clearly touches the surface named by this file.
- `docs/PRD.md` - Managed AIAST surface for Prd. Use it when the task clearly touches the surface named by this file.
- `docs/README.md` - Managed AIAST surface for Readme. Use it when the task clearly touches the surface named by this file.
- `docs/UX_SYSTEM.md` - Managed AIAST surface for UX System. Use it when the task clearly touches the surface named by this file.
- `docs/security/architecture.md` - Managed AIAST surface for Architecture. Use it when the task clearly touches the surface named by this file.
- `docs/security/backend-inventory.md` - Managed AIAST surface for Backend Inventory. Use it when the task clearly touches the surface named by this file.
- `docs/security/rollback.md` - Managed AIAST surface for Rollback. Use it when the task clearly touches the surface named by this file.
- `docs/security/validation.md` - Managed AIAST surface for Validation. Use it when the task clearly touches the surface named by this file.
- `notes/README.md` - Managed AIAST surface for Readme. Use it when the task clearly touches the surface named by this file.
