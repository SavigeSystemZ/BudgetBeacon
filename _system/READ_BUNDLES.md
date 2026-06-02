# Read Bundles

Use the smallest useful bundle for the task instead of defaulting to the full
load order every time.

Every bundle assumes the same startup core:

- `AGENTS.md`
- `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`
- `_system/REPO_OPERATING_PROFILE.md`
- `_system/LOAD_ORDER.md`

Use `LOAD_ORDER.md` when context is cold or the task spans many subsystems.

## Template Evolution Bundle

Use when changing AIAST contracts, validators, prompts, adapters, or managed
operating-system files.

- `_system/CONTEXT_INDEX.md`
- `_system/KEY.md`
- `_system/TEMPLATE_CHANGE_IMPACT_POLICY.md`
- `_system/PROMPT_EMISSION_CONTRACT.md`
- `_system/HOST_BUNDLE_CONTRACT.md`
- `_system/HOST_ADAPTER_POLICY.md`
- `_system/SYSTEM_AWARENESS_PROTOCOL.md`
- `_system/HALLUCINATION_DEFENSE_PROTOCOL.md`
- `bootstrap/validate-instruction-layer.sh`
- `bootstrap/detect-instruction-conflicts.sh`
- `bootstrap/check-system-awareness.sh`

## Repo Onboarding Bundle

Use when orienting in a newly installed repo or recovering after context loss.

- `_system/CONTEXT_INDEX.md`
- `_system/KEY.md`
- `_system/WORKING_FILES_GUIDE.md`
- `_system/TEMPLATE_NEUTRALITY_POLICY.md`
- `_system/PROJECT_PROFILE.md`
- `WHERE_LEFT_OFF.md`
- `TODO.md`
- `PLAN.md`
- `PRODUCT_BRIEF.md`

## Runtime Foundations Bundle

Use when working on runtime scaffolds, install/repair flows, mobile foundations,
AI config, or generated project-owned assets.

- `_system/AGENT_INSTALLER_AND_HOST_VALIDATION_PROTOCOL.md`
- `_system/INSTALLER_AND_UPGRADE_CONTRACT.md`
- `_system/CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md`
- `_system/MOBILE_GUIDE.md`
- `_system/CHATBOT_GUIDE.md`
- `bootstrap/generate-runtime-foundations.sh`
- `bootstrap/check-runtime-foundations.sh`
- `bootstrap/update-template.sh`
- `bootstrap/repair-system.sh`

## Packaging And Distribution Bundle

Use when touching packaging manifests, systemd units, desktop launchers, or
release/install surfaces.

- `_system/PACKAGING_GUIDE.md`
- `_system/INSTALLATION_GUIDE.md`
- `_system/CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md`
- `_system/ports/PORT_POLICY.md`
- `_system/systemd/README.md`
- `bootstrap/check-packaging-targets.sh`
- `bootstrap/generate-systemd-unit.sh`

## Adapter And Host Emission Bundle

Use when changing tool adapters, host prompts, host bundles, Cursor overlays, or
external host ingestion.

- `_system/HOST_ADAPTER_POLICY.md`
- `_system/HOST_BUNDLE_CONTRACT.md`
- `_system/PROMPT_EMISSION_CONTRACT.md`
- `_system/HOOK_AND_ORCHESTRATION_INDEX.md`
- `_system/AGENT_DISCOVERY_MATRIX.md`
- `bootstrap/generate-host-adapters.sh`
- `bootstrap/check-host-adapter-alignment.sh`
- `bootstrap/emit-host-prompt.sh`
- `bootstrap/check-host-ingestion.sh`
- `bootstrap/emit-host-bundle.sh`
- `bootstrap/check-host-bundle.sh`

## Release And Readiness Bundle

Use when hardening for release, validating evidence, or closing a major system
slice.

- `_system/VALIDATION_GATES.md`
- `_system/RELEASE_READINESS_PROTOCOL.md`
- `_system/PROVENANCE_AND_EVIDENCE.md`
- `_system/TEMPLATE_CHANGE_IMPACT_POLICY.md`
- `_system/SELF_HEALING_BOUNDARY.md`
- `bootstrap/validate-system.sh`
- `bootstrap/system-doctor.sh`
- `bootstrap/check-evidence-quality.sh`
- `bootstrap/check-working-file-staleness.sh`

## Repo Pivot Bundle

Use when the task crosses into another repo and the current repo must defer to
target-repo local truth.

- `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`
- `_system/REPO_OPERATING_PROFILE.md`
- `_system/PROMPT_EMISSION_CONTRACT.md`
- `_system/HOST_BUNDLE_CONTRACT.md`
- target repo local instruction files

## Cross-domain archetype presets

Use these presets when the repo serves multiple app categories or the request is
domain-ambiguous. Start with the closest preset and expand only as needed.

**App persona overlay (load if present):** in a downstream app repo where
the app is defined, `_system/personas/APP_PERSONA.md` exists and is the
authoritative app-specific world-class lens — load it *with* the matching
preset below; it sharpens the generic preset with this app's domain/stack
truth (`_system/APP_PERSONA_CONTRACT.md`). Absent in the parent template;
never overrides precedence/security/validation contracts.

### Web/API preset

- `_system/API_DESIGN_STANDARDS.md`
- `_system/SECURITY_BASELINE.md`
- `_system/PERFORMANCE_BUDGET.md`
- `_system/ACCESSIBILITY_STANDARDS.md`

### Mobile preset

- `_system/MOBILE_GUIDE.md`
- `_system/CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md`
- `_system/SECURITY_BASELINE.md`
- `_system/PERFORMANCE_BUDGET.md`

### Desktop/CLI preset

- `_system/MODERN_UI_PATTERNS.md`
- `_system/PACKAGING_GUIDE.md`
- `_system/INSTALLATION_GUIDE.md`
- `_system/SECURITY_HARDENING_CONTRACT.md`

### Data/AI preset

- `_system/PERFORMANCE_BUDGET.md`
- `_system/OBSERVABILITY_STANDARDS.md`
- `_system/DEPENDENCY_GOVERNANCE.md`
- `_system/SECURITY_REDACTION_AND_AUDIT.md`

### Infra/security-heavy preset

- `_system/WORKSPACE_AUTHORITY_AND_CONTAINMENT_PROTOCOL.md`
- `_system/SECURITY_HARDENING_CONTRACT.md`
- `_system/THREAT_MODEL_TEMPLATE.md`
- `_system/VALIDATION_GATES.md`

### Hybrid/unknown-domain preset

- `_system/INSTRUCTION_DOMAIN_ALIGNMENT_PROTOCOL.md`
- `_system/PROJECT_DOMAIN_MANIFEST.json`
- `_system/AGENT_DISCOVERY_MATRIX.md`
- `_system/CONTEXT_INDEX.md`

## Related Contracts

- `_system/TEMPLATE_CHANGE_IMPACT_POLICY.md`
- `_system/SELF_HEALING_BOUNDARY.md`
- `_system/PROJECT_LOCAL_SELF_IMPROVEMENT_PROTOCOL.md`
- `_system/SELF_WRITING_BOUNDARY_AND_ROLLBACK.md`
- `_system/APP_CONTEXT_FILE_MATRIX.md`
- `_system/VERSION_SENSITIVE_RESEARCH_PROTOCOL.md`
- `_system/CONTEXT_BUDGET_STRATEGY.md`
- `_system/APP_BUILDER_REGRESSION_AND_BENCHMARK_PROTOCOL.md`
