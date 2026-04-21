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

## Related Contracts

- `_system/TEMPLATE_CHANGE_IMPACT_POLICY.md`
- `_system/SELF_HEALING_BOUNDARY.md`
- `_system/VERSION_SENSITIVE_RESEARCH_PROTOCOL.md`
- `_system/CONTEXT_BUDGET_STRATEGY.md`
