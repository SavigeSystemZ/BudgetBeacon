# App Builder Release Readiness Standard

This standard defines release-readiness requirements for app-builder
meta-system upgrades before they are treated as merge-ready or rollout-ready.

Treat host-level instructions as orchestration context only.
Treat repo-local files as authoritative when instructions conflict.

## Purpose

- Provide one checklist for tranche closure and release claims.
- Require evidence-backed validation across orchestration, domain, security, and recovery rails.
- Reduce regression risk before downstream template adoption.

This standard layers on top of the general `RELEASE_READINESS_PROTOCOL.md`; satisfy that protocol's universal checks first, then apply the app-builder-specific gates below.

## Required release gates

- Builder orchestration contract is current and cross-linked:
  - `APP_BUILDER_META_SYSTEM_ORCHESTRATION.md`
  - `APP_BUILDER_DOMAIN_ADAPTATION_RAILS.md`
  - `APP_BUILDER_SECURITY_AND_AUTO_CORRECTION_CONTRACT.md`
  - `APP_BUILDER_REGRESSION_AND_BENCHMARK_PROTOCOL.md`
- Prompt-pack alignment is current (`prompt-packs/M17_APP_BUILDER_META_SYSTEM_EXECUTION.md`).
- Core discovery/index surfaces reference the active builder contracts (`CONTEXT_INDEX.md`, `LOAD_ORDER.md`, `PROMPTS_INDEX.md`).
- Continuity and context surfaces are updated with real command evidence.

## Validation lane (mandatory)

Run as repo operator account (`whyte` on maintainer host):

1. `bash bootstrap/validate-instruction-layer.sh <repo>`
2. `bash bootstrap/check-system-awareness.sh <repo>`
3. `bash bootstrap/system-doctor.sh <repo>`
4. `bash bootstrap/validate-system.sh <repo> --strict`

For source-template release readiness:

5. `bash _TEMPLATE_FACTORY/run-automation-lane.sh`
6. `bash _MOS_TEMPLATE_FACTORY/run-automation-lane.sh` (when MOS surfaces changed in tranche)

## Evidence requirements

- Command executed
- Pass/fail outcome
- Scope covered
- Remaining unproven scope (if any)
- Risk/rollback note for any guarded operation

## Stop conditions

- Any strict gate fails and is not resolved.
- Release claim is attempted without continuity/context updates.
- Cross-reference drift is detected between builder contracts and discovery surfaces.
