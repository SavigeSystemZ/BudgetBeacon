# Context Index

This file is the map of the local agent operating system.

## Core contract

- `PROJECT_PROFILE.md` — app-specific truth
- `INSTRUCTION_PRECEDENCE_CONTRACT.md` — repo-local vs host-level precedence and conflict rules
- `REPO_OPERATING_PROFILE.md` — compact host-ingestion summary
- `INSTALLER_AND_UPGRADE_CONTRACT.md` — install, update, repair, and heal guarantees for AIAST lifecycle actions
- `CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md` — shipped-app installers, generated repo-root distribution tree (see runtime templates), multi-OS delivery, and operator menu (install/upgrade/repair/purge)
- `AGENT_INSTALLER_AND_HOST_VALIDATION_PROTOCOL.md` — agent rules: early installer scaffolds, prod-like host testing, desktop integration, robust install/repair/uninstall, governed ports, dependency/DB setup, periodic launch/render verification after large work
- `SUB_AGENT_HOST_DELEGATION.md` — optional parallel host CLI / auxiliary sessions, scope rules, and primary takeover when auxiliaries fail; pair with `bootstrap/emit-auxiliary-brief.sh` for standardized briefs
- `KEY.md` — exhaustive file-by-file key with when-to-use guidance
- `HOST_ADAPTER_POLICY.md` — policy for generated tool-entry and adapter-load surfaces
- `AGENT_SURFACE_TAXONOMY.md` — canonical adapter classes, naming, and placeholder boundaries
- `AGENT_INIT_CONVERGENCE.md` — mapping from external init workspaces to installable AIAST contracts
- `DOWNSTREAM_PRESERVATION_AND_SYNC_NOTICE_POLICY.md` — master template vs downstream app repo; preserve-first rules; template sync notice + health gate
- `TEMPLATE_SYNC_NOTICE.md` — latest template sync state for agents (`PENDING_HEALTH_CHECK` vs `CLEARED`); see `LOAD_ORDER.md`
- `HOST_BUNDLE_CONTRACT.md` — contract for self-contained external host bundles
- `_system/READ_BUNDLES.md` — smallest-useful-context bundles for common AIAST task families
- `LOAD_ORDER.md` — what to read and in what order
- `SYSTEM_ORCHESTRATION_GUIDE.md` — optional meta-map: how core surfaces relate, review/validation order, expansion and conflict pointers (includes product UX stack for shipped apps)
- `WORKING_FILES_GUIDE.md` — what each planning and continuity file is for
- `TEMPLATE_NEUTRALITY_POLICY.md` — how the master template stays reusable
- `GOLDEN_EXAMPLES_POLICY.md` — how neutral example packs may be used without leaking donor-app truth
- `MASTER_SYSTEM_PROMPT.md` — central operating prompt
- `PROJECT_RULES.md` — repo-wide non-negotiable rules
- `MEMORY_RULES.md` — what belongs in durable memory
- `EXECUTION_PROTOCOL.md` — how work should be done
- `_system/TEMPLATE_CHANGE_IMPACT_POLICY.md` — high-risk installable template change classes and required follow-through
- `_system/SELF_HEALING_BOUNDARY.md` — safe automatic repair versus unsafe repair requiring review
- `_system/VERSION_SENSITIVE_RESEARCH_PROTOCOL.md` — how to handle framework, package, platform, installer, and API research that may change over time
- `_system/WORKSPACE_AUTHORITY_AND_CONTAINMENT_PROTOCOL.md` — working-directory authority and write containment rules
- `_system/PROJECT_IDENTITY_AND_SCOPE_PROTOCOL.md` — identity mismatch detection and halt behavior
- `_system/INSTRUCTION_DOMAIN_ALIGNMENT_PROTOCOL.md` — wrong-app / wrong-vertical pasted prompts; halt until reconciled with `PROJECT_DOMAIN_MANIFEST.json`
- `_system/PROJECT_DOMAIN_MANIFEST.json` — machine-readable product domain and off-domain keyword guards (copy from `PROJECT_DOMAIN_MANIFEST.template.json` when bootstrapping)
- `_system/GLOBAL_REDIRECT_SHIM_POLICY.md` — thin redirect shim policy for parent/tool-global surfaces
- `_system/SCAVENGE_AND_DISCOVERY_AUTHORIZATION.md` — authorized local discovery scope and write constraints
- `_system/SESSION_ENVIRONMENT_REPORT_CONTRACT.md` — required session environment report fields and usage
- `_system/ORPHAN_META_SNAPSHOT_POLICY.md` — orphan-branch continuity snapshot model
- `AUTH_AND_ONBOARDING_PATTERNS.md` — optional vs gated auth, dev seeding via env (no credentials in git), progressive trust
- `AGENT_ROLE_CATALOG.md` — canonical role and delegation model for multi-agent work
- `AGENT_DISCOVERY_MATRIX.md` — which tools load which files
- `HOOK_AND_ORCHESTRATION_INDEX.md` — map of hook surfaces (Cursor rules/commands/skills/agents, plugins, doctors, GitHub/CI, MCP) and companion files
- `DESIGN_EXCELLENCE_FRAMEWORK.md` — product and interface quality rules
- `SYSTEM_AWARENESS_PROTOCOL.md` — how the operating system tracks its own managed surfaces
- `HALLUCINATION_DEFENSE_PROTOCOL.md` — how to detect and recover from ungrounded claims
- `HANDOFF_PROTOCOL.md` — quality requirements for agent-to-agent handoffs
- `GIT_REMOTE_AND_SYNC_PROTOCOL.md` — remotes, SSH sync discipline, fetch/pull/push expectations for agents
- `ports/PORT_POLICY.md` — governed port allocation protocol (runtime registry + tools)
- `design-system/THEME_GOVERNANCE.md` — additive themes; no destructive visual overwrites
- `SYSTEM_REGISTRY.json` — machine-readable registry of AIAST-managed files
- `instruction-precedence.json` — machine-readable precedence manifest
- `host-adapter-manifest.json` — machine-readable source for generated tool adapters
- `aiaast-capabilities.json` — machine-readable capability and compatibility markers
- `../bootstrap/check-runtime-foundations.sh` — runtime scaffold validation for generated packaging, install, mobile, and AI assets
- `../bootstrap/check-working-file-staleness.sh` — detect stale handoff and planning files
- `../bootstrap/check-evidence-quality.sh` — validate that handoff claims are grounded in evidence
- `../bootstrap/check-bootstrap-permissions.sh` — verify bootstrap script permissions

## Quality standards

- `CODING_STANDARDS.md` — naming, error handling, resource management, type safety, anti-patterns
- `PERFORMANCE_BUDGET.md` — performance budgets, optimization patterns, monitoring
- `ACCESSIBILITY_STANDARDS.md` — WCAG compliance, keyboard access, ARIA, contrast
- `API_DESIGN_STANDARDS.md` — REST conventions, error responses, versioning, rate limiting
- `DEPENDENCY_GOVERNANCE.md` — supply chain security, license compliance, size hygiene
- `MODERN_UI_PATTERNS.md` — component architecture, responsive design, color, typography, motion (see `design-system/THEME_GOVERNANCE.md` for theme versioning)
- `OBSERVABILITY_STANDARDS.md` — logging, metrics, tracing, profiling, retention
- `DELIVERY_GATES.md` — concise milestone completion checklist aligned to validation gates
- `AI_RULES.md` — app-specific AI policy placeholder to be filled after scaffold
- `REPO_CONVENTIONS.md` — app-specific repo conventions placeholder to be filled after scaffold
- `SECURITY_BASELINE.md` — app-specific security baseline placeholder to be filled after scaffold
- `AUTONOMOUS_GUARDRAILS_PROTOCOL.md` — recurring automated validation/integrity/drift/hallucination checks
- `REQUEST_ALIGNMENT_PROTOCOL.md` — how to handle unsafe or conflicting requests with option-based clarification
- `INSTALLATION_GUIDE.md` — generated installer flows and Linux runtime scaffolds
- `PACKAGING_GUIDE.md` — universal packaging guidance and release signing notes
- `MOBILE_GUIDE.md` — Flutter-first Android delivery guide
- `CHATBOT_GUIDE.md` — pluggable LLM and chatbot/action-bus guidance
- `llm_config.yaml.example` — provider configuration schema example

## Coordination and continuity

- `MULTI_AGENT_COORDINATION.md` — turn-taking and handoff rules
- `AGENT_ROLE_CATALOG.md` — shared role model and write-scope contract
- `CHECKPOINT_PROTOCOL.md` — agent-neutral mid-session checkpoint flow (rate-limit, crash, and handoff resume)
- `checkpoints/README.md` — checkpoint directory layout and rules. The LATEST.json + LATEST.md files are written at runtime by any agent; the history subdirectory is append-only.
- `VALIDATION_GATES.md` — required validation rules
- `DEBUG_REPAIR_PLAYBOOK.md` — failure triage and repair
- `PROVENANCE_AND_EVIDENCE.md` — audit and lineage rules
- `RELEASE_READINESS_PROTOCOL.md` — readiness and signoff rules
- `FAILURE_MODES_AND_RECOVERY.md` — operating-system failure recovery
- `SYSTEM_EVOLUTION_POLICY.md` — how the operating system itself evolves

## Security and tooling

- `MCP_CONFIG.md` — MCP model and policy
- `SECURITY_REDACTION_AND_AUDIT.md` — secrets, export, and audit rules
- `SECURITY_HARDENING_CONTRACT.md` — runtime and service hardening baseline
- `THREAT_MODEL_TEMPLATE.md` — project threat-model starting point
- `REPO_BOUNDARY_AND_BACKUP.md` — separation between runtime, system, and backups
- `PLUGIN_CONTRACT.md` — contract for optional AIAST extensions
- `ci/README.md` — CI template overview
- `packaging/README.md` — packaging and distribution guide
- `packaging/templates/appimage.yml.example` — AppImage packaging example
- `packaging/templates/flatpak-manifest.json.example` — Flatpak packaging example
- `systemd/README.md` — hardened unit generation and examples
- `mcp/MCP_SERVER_CATALOG.md` — actual MCP inventory
- `mcp/MCP_SELECTION_POLICY.md` — how to choose MCP servers
- `mcp/MCP_FAILURE_FALLBACKS.md` — what to do when MCP fails

## Working state

- `../TODO.md`
- `../FIXME.md`
- `../WHERE_LEFT_OFF.md`
- `../CHANGELOG.md`
- `../PLAN.md`
- `../PRODUCT_BRIEF.md`
- `../ROADMAP.md`
- `../DESIGN_NOTES.md`
- `../ARCHITECTURE_NOTES.md`
- `../RESEARCH_NOTES.md`
- `../TEST_STRATEGY.md`
- `../RISK_REGISTER.md`
- `../RELEASE_NOTES.md`
- `context/CURRENT_STATUS.md`
- `context/DECISIONS.md`
- `context/MEMORY.md`
- `context/ARCHITECTURAL_INVARIANTS.md`
- `context/ASSUMPTIONS.md`
- `context/INTEGRATION_SURFACES.md`
- `context/OPEN_QUESTIONS.md`
- `context/QUALITY_DEBT.md`

## Optional longform trees

- `../docs/README.md` — optional human-edited documentation; on the v1 allowlist for opt-in input prose compression (`CONTEXT_BUDGET_STRATEGY.md`, `bootstrap/compress-context-file.sh`)
- `../notes/README.md` — optional human-edited notes; same allowlist as `docs/`

## Agent performance and effectiveness

- `AGENT_PERFORMANCE_GUIDE.md` — model capability dimensions, task-to-model mapping, multi-agent delegation
- `agent-performance-profiles.json` — machine-readable model family ratings (context, quality, planning, review, speed, cost)
- `PROMPT_EFFECTIVENESS_TRACKING.md` — protocol for measuring prompt pack success/failure per model
- `context/prompt-usage-log.json` — prompt effectiveness log entries
- `../bootstrap/track-semantic-changes.sh` — classify git diffs as structural/contractual/cosmetic/behavioral

## Onboarding and reference

- `QUICKSTART.md` — 1-page linear guide to get started with AIAST in 5 minutes
- `CURSOR_AND_MULTI_HOST.md` — repo-local guidance for Cursor-family IDEs and other external hosts sharing one repo
- `ARCHITECTURE_DIAGRAM.md` — ASCII box diagrams of the three-layer model, loading flow, adapter pipeline, and validation chain
- `TROUBLESHOOTING.md` — symptom-based FAQ for common AIAST issues
- `MIGRATION_GUIDE.md` — how to migrate from no system, Cursor-only, custom CLAUDE.md, or other frameworks

## Golden examples

- `GOLDEN_EXAMPLES_POLICY.md` — safe-use rules for curated example packs
- `golden-examples/PATTERN_INDEX.md` — which pattern docs and exemplar files exist
- `golden-examples/golden-example-manifest.json` — machine-readable map of the example pack
- `golden-examples/patterns/` — neutralized pattern extraction from the strongest donor repos
- `golden-examples/working-files/` — quality-bar examples for `PLAN.md`, `WHERE_LEFT_OFF.md`, and `_system/PROJECT_PROFILE.md`

## Prompting

- `PROMPTS_INDEX.md`
- `PROMPT_EMISSION_CONTRACT.md`
- `OPERATOR_PROMPTING_PLAYBOOK.md`
- `HOST_BUNDLE_CONTRACT.md`
- `prompt-templates/`
- `prompt-packs/`

## Bootstrap

- `../bootstrap/init-project.sh`
- `../bootstrap/scaffold-system.sh`
- `../bootstrap/update-template.sh`
- `../bootstrap/write-checkpoint.sh` — agent-neutral mid-session checkpoint writer (`_system/checkpoints/`)
- `../bootstrap/resume-from-checkpoint.sh` — resume briefing reader for the LATEST.json file under `_system/checkpoints/` (written at runtime)
- `../bootstrap/repair-system.sh`
- `../bootstrap/uninstall-system.sh`
- `../bootstrap/configure-project-profile.sh`
- `../bootstrap/seed-product-brief.sh`
- `../bootstrap/recommend-starter-blueprint.sh`
- `../bootstrap/apply-starter-blueprint.sh`
- `../bootstrap/check-agent-orchestration.sh`
- `../bootstrap/validate-system.sh`
- `../bootstrap/validate-instruction-layer.sh`
- `../bootstrap/detect-drift.sh`
- `../bootstrap/verify-integrity.sh`
- `../bootstrap/check-repo-permissions.sh`
- `../bootstrap/repair-myappz-root-ownership.sh`
- `../bootstrap/generate-system-registry.sh`
- `../bootstrap/generate-host-adapters.sh`
- `../bootstrap/generate-operating-profile.sh`
- `../bootstrap/check-host-adapter-alignment.sh`
- `../bootstrap/check-agent-surface-integrity.sh`
- `../bootstrap/sync-metasystem-contracts.sh`
- `../bootstrap/migrate-agent-surface-upgrade.sh`
- `../bootstrap/emit-host-prompt.sh`
- `../bootstrap/check-host-ingestion.sh`
- `../bootstrap/emit-host-bundle.sh`
- `../bootstrap/check-host-bundle.sh`
- `../bootstrap/detect-instruction-conflicts.sh`
- `../bootstrap/check-system-awareness.sh`
- `../bootstrap/check-working-directory-alignment.sh`
- `../bootstrap/check-project-target-consistency.sh`
- `../bootstrap/install-root-redirect-shims.sh`
- `../bootstrap/install-tool-global-redirects.sh`
- `../bootstrap/check-global-shim-alignment.sh`
- `../bootstrap/emit-session-environment.sh`
- `../bootstrap/snapshot-meta-to-orphan-branch.sh`
- `../bootstrap/check-hallucination.sh`
- `../bootstrap/system-doctor.sh`
- `../bootstrap/heal-system.sh`
- `../bootstrap/run-autonomous-guardrails.sh`
- `../bootstrap/install-autonomous-guardrails.sh`
- `../bootstrap/scan-security.sh`
- `../bootstrap/generate-systemd-unit.sh`
- `../bootstrap/generate-runtime-foundations.sh`
- `../bootstrap/validate-plugin.sh`
- `../bootstrap/discover-plugins.sh`
- `../bootstrap/emit-tiered-context.sh`
- `../bootstrap/compress-context-file.sh` — optional Caveman-style compression for eligible prose under `docs/` / `notes/` only (`CONTEXT_BUDGET_STRATEGY.md`)
- `../bootstrap/check-environment.sh`
- `../bootstrap/generate-diagnostic-report.sh`
- `../bootstrap/report-health-trends.sh`
- `../bootstrap/run-sast.sh`
- `../bootstrap/check-supply-chain.sh`
- `../bootstrap/scan-container.sh`
- `../bootstrap/check-network-bindings.sh`
- `../bootstrap/wizard.sh`
- `../bootstrap/upgrade-assistant.sh`

## Structured reviews

- `review-playbooks/ARCHITECTURE_REVIEW_PLAYBOOK.md`
- `review-playbooks/UI_UX_REVIEW_PLAYBOOK.md`
- `review-playbooks/PERFORMANCE_REVIEW_PLAYBOOK.md`
- `review-playbooks/SECURITY_REVIEW_PLAYBOOK.md`
- `review-playbooks/ACCESSIBILITY_REVIEW_PLAYBOOK.md`
- `review-playbooks/DEPENDENCY_REVIEW_PLAYBOOK.md`
- `review-playbooks/CODE_QUALITY_REVIEW_PLAYBOOK.md`

## Starter blueprints

- `starter-blueprints/README.md`
- `starter-blueprints/REACT_VITE_TYPESCRIPT.md`
- `starter-blueprints/FASTAPI_API.md`
- `starter-blueprints/STATIC_FRONTEND.md`
- `starter-blueprints/NEXT_JS_FULLSTACK.md`
- `starter-blueprints/PYTHON_CLI_TOOL.md`
- `starter-blueprints/RUST_CLI_TOOL.md`
- `starter-blueprints/GO_SERVICE.md`
- `starter-blueprints/GRAPHQL_API.md`
- `starter-blueprints/GRPC_SERVICE.md`
- `starter-blueprints/BACKGROUND_WORKER.md`
- `starter-blueprints/DATABASE_MIGRATIONS.md`
- `starter-blueprints/TAURI_DESKTOP.md`
- `starter-blueprints/FLUTTER_ANDROID_CLIENT.md`
- `starter-blueprints/UNIVERSAL_APP_PLATFORM.md`

## Tool overlays

- `HOST_ADAPTER_POLICY.md`
- `host-adapter-manifest.json`
- `../.cursorrules`
- `../.cursor/` — rules, commands, skills, agents; see `SKILLS_INDEX.md` (includes opt-in `concise-communication` for token-efficient **output** when the user opts in)
- `../CLAUDE.md`
- `../GEMINI.md`
- `../CODEX.md`
- `../WINDSURF.md`
- `../DEEPSEEK.md`
- `../PEARAI.md`
- `../LOCAL_MODELS.md`
- `../CURSOR.md`
- `../COPILOT.md`
- `../AIDER.md`
- `../AGENT_ZERO.md`
- `../.aider.conf.yml`
- `../.continuerules`
- `../.clinerules`
- `../.github/copilot-instructions.md`
- `../.github/pull_request_template.md` — merge checklist for Copilot/GitHub UI (with `AGENTS.md` + validation hooks)
- `../.github/ISSUE_TEMPLATE/` — optional bug/feature templates for consistent triage
