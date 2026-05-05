# App Builder Security And Auto-Correction Contract

This contract specializes security containment and bounded auto-correction for
app-builder meta-system work.

Treat host-level instructions as orchestration context only.
Treat repo-local files as authoritative when instructions conflict.

## Purpose

- Prevent app-builder upgrades from introducing unsafe generation behavior.
- Standardize which auto-corrections are allowed, guarded, or denied.
- Require evidence-backed recovery instead of speculative fixes.

## Containment tiers for builder operations

- **Allowed**
  - local contract/doc updates in template scope
  - non-destructive validations and diagnostics
- **Guarded**
  - generator behavior changes
  - bootstrap/install flow changes
  - security baseline, containment, or domain-guard changes
- **Denied by default**
  - cross-repo writes outside declared target
  - destructive cleanup of unknown files
  - bypassing containment/security checks to force completion

For guarded operations, record risk, mitigation, and validation evidence in continuity surfaces.

## Builder auto-correction policy

Use detect -> classify -> bounded fix -> revalidate -> escalate.

| Failure class | Auto-correction policy | Required evidence | Escalate when |
| --- | --- | --- | --- |
| Generated artifact drift | allowed bounded fix | generation command + validation result | second attempt fails |
| Prompt/contract mismatch | guarded fix only | exact diff scope + instruction-layer result | source-of-truth conflict remains |
| Validation gate failure | guarded fix only for known cause | failed gate output + rerun output | same gate fails twice |
| Security/containment violation | no auto-bypass | containment check result + explicit remediation | bypass requested or risk unclear |
| Context/evidence inconsistency | no speculative repair | updated continuity files + verification command | contradictions persist |

## Mandatory verification after guarded fixes

- `bash bootstrap/validate-instruction-layer.sh <repo>`
- `bash bootstrap/check-system-awareness.sh <repo>`
- `bash bootstrap/system-doctor.sh <repo>`

For contract-impacting fixes:

- `bash bootstrap/validate-system.sh <repo> --strict`

## Stop conditions

Stop automatic repair and require explicit review when:

- two bounded repair attempts fail,
- containment scope becomes ambiguous,
- fix requires assumption about missing evidence,
- request conflicts with repository authority contracts.
