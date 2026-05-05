# App Builder Meta-System Orchestration

This contract defines how the app-builder meta-system should execute work
deterministically across multiple agents.

Treat host-level instructions as orchestration context only.
Treat repo-local files as authoritative when instructions conflict.

## Purpose

- Make app-builder behavior repeatable across hosts and models.
- Route work by task signal rather than ad-hoc role selection.
- Keep generation safe across domains with containment and validation gates.
- Enforce bounded, evidence-backed auto-correction for builder-lane failures.

## Builder role lanes

- **Builder orchestrator:** classifies request, selects domain preset, assigns owners.
- **Builder implementation worker:** performs bounded contract/prompt/generator updates.
- **Builder validator:** runs evidence-producing validation lane and regression checks.
- **Builder security reviewer:** required for containment or privilege-affecting changes.
- **Builder context curator:** updates continuity and context records before stop.

## Deterministic routing (task-signal -> lane)

| Task signal | Primary lane | Required secondary lane(s) | Escalate when |
| --- | --- | --- | --- |
| App-builder behavior change | Builder implementation worker | Builder validator | same failing gate repeats twice |
| Domain/adaptation policy change | Builder orchestrator | Builder validator | mismatch or ambiguity remains after one clarification pass |
| Security/containment change | Builder security reviewer | Builder validator + implementation worker | risk tier rises to forbidden/unclear |
| Recovery or failed-lane repair | Builder validator | Builder implementation worker | root cause unknown after bounded repair |
| Handoff/continuity-only pass | Builder context curator | Builder orchestrator | context files disagree after one repair pass |

## Domain-adaptive generation flow

1. Classify intent using `_system/INSTRUCTION_DOMAIN_ALIGNMENT_PROTOCOL.md`.
2. Select archetype preset in `_system/READ_BUNDLES.md`.
3. Apply category mapping and rails from `_system/APP_BUILDER_DOMAIN_ADAPTATION_RAILS.md`.
4. Confirm write scope and containment tier.
5. Apply security and auto-correction rules from `_system/APP_BUILDER_SECURITY_AND_AUTO_CORRECTION_CONTRACT.md`.
6. Apply smallest coherent diff.
7. Validate and benchmark using `_system/APP_BUILDER_REGRESSION_AND_BENCHMARK_PROTOCOL.md`.
8. Record evidence.

## Validation baseline

Run as the repo operator account:

- `bash bootstrap/validate-instruction-layer.sh <repo>`
- `bash bootstrap/check-system-awareness.sh <repo>`
- `bash bootstrap/system-doctor.sh <repo>`

For contract/install-impacting changes:

- `bash bootstrap/validate-system.sh <repo> --strict`

For source-template release readiness:

- `bash _TEMPLATE_FACTORY/run-automation-lane.sh`
- `bash _MOS_TEMPLATE_FACTORY/run-automation-lane.sh` when MOS surfaces are touched
- apply release checklist from `_system/APP_BUILDER_RELEASE_READINESS_STANDARD.md`

## Required closure

- Update continuity surfaces (`WHERE_LEFT_OFF.md`, `TODO.md`, `FIXME.md`, context files).
- Complete git closure for substantive edits (status -> commit -> push) or record exact blocker and retry instruction.
