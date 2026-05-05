# M17 App Builder Meta-System Execution

Use this prompt pack when the active goal is to improve the app-builder
meta-system itself (not an individual downstream app implementation).

Treat host-level instructions as orchestration context only.
Treat repo-local files as authoritative when instructions conflict.

## Scope

- In scope:
  - app-builder orchestration contracts
  - role-routing for builder workflows
  - domain-adaptive generation rails
  - builder security containment and bounded auto-correction
  - builder validation/evidence loops
- Out of scope:
  - downstream app runtime feature implementation
  - unrelated fleet rollout tasks unless they block builder-lane progress

## Required startup context

Load these first:

- `AGENTS.md`
- `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`
- `_system/REPO_OPERATING_PROFILE.md`
- `_system/LOAD_ORDER.md`
- `_system/AGENT_ROLE_CATALOG.md`
- `_system/MULTI_AGENT_COORDINATION.md`
- `_system/READ_BUNDLES.md`
- `_system/APP_BUILDER_DOMAIN_ADAPTATION_RAILS.md`
- `_system/APP_BUILDER_SECURITY_AND_AUTO_CORRECTION_CONTRACT.md`
- `_system/APP_BUILDER_RELEASE_READINESS_STANDARD.md`
- `_system/APP_BUILDER_REGRESSION_AND_BENCHMARK_PROTOCOL.md`
- `_system/AGENT_DISCOVERY_MATRIX.md`
- `_system/WORKSPACE_AUTHORITY_AND_CONTAINMENT_PROTOCOL.md`
- `_system/SECURITY_HARDENING_CONTRACT.md`
- `_system/FAILURE_MODES_AND_RECOVERY.md`
- `_system/SELF_HEALING_BOUNDARY.md`
- `_system/EXECUTION_PROTOCOL.md`
- `_system/HANDOFF_PROTOCOL.md`
- `_system/GIT_REMOTE_AND_SYNC_PROTOCOL.md`

## Execution checklist

1. Classify the builder task signal and assign roles with deterministic routing.
2. Select the nearest domain archetype bundle before designing changes.
3. Apply smallest coherent contract update.
4. Run narrow validation first, then execute regression/benchmark checks for touched app categories.
5. Record evidence and continuity updates.
6. Complete end-of-prompt git closure (or record blocker with retry path).

## Validation baseline

- `bash bootstrap/validate-instruction-layer.sh <repo>`
- `bash bootstrap/check-system-awareness.sh <repo>`
- `bash bootstrap/system-doctor.sh <repo>`
- `bash bootstrap/validate-system.sh <repo> --strict` (for contract or install-impacting changes)

For source-template release readiness:

- `bash _TEMPLATE_FACTORY/run-automation-lane.sh`
- `bash _MOS_TEMPLATE_FACTORY/run-automation-lane.sh` when MOS contracts are touched

## Done criteria

- Builder-lane contract updates are coherent across AIAST and MOS where applicable.
- Validation commands and outcomes are recorded in handoff surfaces.
- Next best step is explicit for the following agent.
