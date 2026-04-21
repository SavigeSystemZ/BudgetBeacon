# Prompts Index

When authoring or reorganizing prompts, packs, or tiered context, read `_system/SYSTEM_ORCHESTRATION_GUIDE.md` once for how prompt surfaces relate to validation order, hooks, and expansion paths.

## Prompt templates

- `_system/PROMPT_EMISSION_CONTRACT.md`
- `_system/PROMPT_SYSTEM_BUILD_STANDARD.md`
- `_system/PROMPT_SECURITY_BASELINE.md`
- `_system/PROMPT_BACKEND_POLICY.md`
- `_system/PROMPT_DOCKER_NETWORK_POLICY.md`
- `_system/HOST_BUNDLE_CONTRACT.md`
- `bootstrap/emit-host-prompt.sh`
- `bootstrap/emit-host-bundle.sh`
- `bootstrap/check-host-bundle.sh`
- `_system/prompt-templates/system_prompt_template.md`
- `_system/prompt-templates/developer_prompt_template.md`
- `_system/prompt-templates/user_prompt_template.md`
- `_system/prompt-templates/architecture_prompt_template.md`
- `_system/prompt-templates/repair_prompt_template.md`
- `_system/prompt-templates/review_prompt_template.md`
- `_system/prompt-templates/optimization_prompt_template.md`

## Milestone prompt packs

- `_system/prompt-packs/M0_FOUNDATION.md`
- `_system/prompt-packs/M1_FEATURE_DELIVERY.md`
- `_system/prompt-packs/M2_DEBUG_AND_STABILIZE.md`
- `_system/prompt-packs/M3_REVIEW_AND_RELEASE.md`
- `_system/prompt-packs/M4_ARCHITECTURE_EXPANSION.md`
- `_system/prompt-packs/M5_MIGRATION_AND_REFACTOR.md`
- `_system/prompt-packs/M6_INSTALL_AND_DISTRIBUTION.md`
- `_system/prompt-packs/M7_DESIGN_EXCELLENCE.md`
- `_system/prompt-packs/M8_SECURITY_AND_COMPLIANCE.md`
- `_system/prompt-packs/M9_MULTI_AGENT_CONTINUITY.md`
- `_system/prompt-packs/M10_GREENFIELD_BOOTSTRAP.md`
- `_system/prompt-packs/M11_MATURE_REPO_RETROFIT.md`
- `_system/prompt-packs/M12_PERFORMANCE_OPTIMIZATION.md`
- `_system/prompt-packs/M13_ACCESSIBILITY_AND_INCLUSION.md`
- `_system/prompt-packs/M14_SECURITY_HARDENING.md`
- `_system/prompt-packs/M15_WHOLE_REPO_ANALYSIS.md`
- `_system/prompt-packs/M16_PLATFORM_PRODUCT_EXPANSION.md`

## Prompt effectiveness tracking

- `_system/PROMPT_EFFECTIVENESS_TRACKING.md` — protocol for measuring prompt pack success/failure per model
- `_system/context/prompt-usage-log.json` — log of prompt pack usage outcomes
- `_system/AGENT_PERFORMANCE_GUIDE.md` — model capability profiles that inform prompt pack selection

## Context budget and tiered loading

- `_system/CONTEXT_BUDGET_STRATEGY.md` — 4-tier loading model (A/B/C/D) by context window
- `_system/context-budget-profiles.json` — machine-readable model-to-tier mappings
- `bootstrap/emit-tiered-context.sh` — emits tier-appropriate file lists for context-constrained models
- `bootstrap/compress-context-file.sh` — **opt-in** input prose compression (allowlisted paths only); requires upstream caveman-compress and `claude` CLI; see `CONTEXT_BUDGET_STRATEGY.md` and `/compress-context`
- `bootstrap/emit-auxiliary-brief.sh` — emits a markdown brief for optional parallel host CLI / IDE workers (`SUB_AGENT_HOST_DELEGATION.md`)

## Rules for all prompt packs

- reference canonical docs by file name; for a map of related OS surfaces, use `_system/SYSTEM_ORCHESTRATION_GUIDE.md`
- follow `_system/PROMPT_EMISSION_CONTRACT.md`
- state scope explicitly
- require minimal diffs
- require validation
- require handoff updates
- avoid hidden assumptions
- keep prompts copy-paste ready
- keep exported host bundles self-contained and narrow
- consult the golden example pack when creating a new prompt subsystem or rewriting prompt-pack structure
