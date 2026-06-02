# App Builder Regression And Benchmark Protocol

This protocol defines how app-builder meta-system changes prove they do not
degrade generation quality, safety, or operating cost.

Treat host-level instructions as orchestration context only.
Treat repo-local files as authoritative when instructions conflict.

## Purpose

- Add repeatable regression checks for builder-lane contract and prompt changes.
- Require before/after evidence for quality, safety, and effort-to-repair.
- Prevent release claims that are not backed by benchmark evidence.

This protocol scopes the **regression bar for app-builder contract/prompt changes**. For the underlying benchmark campaign infrastructure (test-app scaffolding, archetype/profile coverage matrix, gate execution model, evidence layout) see `TEST_APP_BENCHMARK_CAMPAIGN_PROTOCOL.md` and the executable surface `bootstrap/run-test-app-benchmark-matrix.sh`.

## Regression set (minimum)

Run a representative set of app-builder requests across categories:

- web/api
- mobile
- desktop/cli
- data/ai
- infra/security-heavy
- hybrid/unknown

For each request, record:

- task classification and selected archetype
- contracts touched
- validation commands run
- pass/fail outcome
- manual interventions required

## Benchmark dimensions

Track these dimensions for each tranche:

- **Correct routing rate:** request classified to the intended lane and archetype.
- **Containment adherence:** no forbidden operations and no bypassed guarded checks.
- **Bounded repair success:** failures resolved within two bounded repair attempts.
- **Validation completion:** required strict gates complete without unresolved failures.
- **Operational friction:** count of manual recovery steps required by maintainers.

## Required evidence format

Store evidence in maintainer continuity surfaces with:

- timestamp
- command list
- outcomes
- unresolved risk
- rollback note for guarded operations

Preferred locations:

- `_META_AGENT_SYSTEM/evidence/`
- `_META_AGENT_SYSTEM/context/CURRENT_STATUS.md`

## Validation baseline

- `bash bootstrap/validate-instruction-layer.sh <repo>`
- `bash bootstrap/check-system-awareness.sh <repo>`
- `bash bootstrap/system-doctor.sh <repo>`
- `bash bootstrap/validate-system.sh <repo> --strict`

When source-template release readiness is claimed:

- `bash _TEMPLATE_FACTORY/run-automation-lane.sh`
- `bash _MOS_TEMPLATE_FACTORY/run-automation-lane.sh` (if MOS surfaces changed)

## Stop conditions

Stop release progression and require explicit review when:

- any benchmark dimension regresses without mitigation,
- benchmark evidence is missing for a touched app category,
- containment or validation failures recur after two bounded repairs.
