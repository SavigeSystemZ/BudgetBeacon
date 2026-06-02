# Self-Healing Boundary

AIAST self-healing is conservative repair of known-safe mechanical drift. It is
not permission to erase uncertainty, overwrite repo-owned truth, or silently
"fix" user-directed behavior.

## Self-healing vs self-writing

Self-healing is *mechanical repair* of known drift (this document). *Additive
improvement* of a downstream repo's local operating layer is a different
activity, bounded separately by `SELF_WRITING_BOUNDARY_AND_ROLLBACK.md` and
`PROJECT_LOCAL_SELF_IMPROVEMENT_PROTOCOL.md`. Neither may cross a repo boundary
or overwrite repo-owned truth.

## Safe automatic repairs

- regenerate managed host adapters from canonical manifests
- regenerate the operating profile, system registry, and integrity manifest
- restore executable bits on managed bootstrap scripts
- restore missing template-managed files through the documented additive repair
  flow
- repair missing managed directories or runtime-foundation scaffolds when the
  repair path already preserves repo-owned content

## Unsafe repairs

- overwriting repo-owned working files
- overwriting `_system/context/` state with template defaults
- deleting unknown files
- inventing missing repo facts to fill placeholders
- rewriting project profile, app rules, repo conventions, or security baseline
  without evidence
- replacing user-directed rules because they look unconventional
- claiming validation or recovery success when uncertainty remains

## Standard repair order

1. Run `bootstrap/validate-system.sh <repo>`.
2. Run `bootstrap/system-doctor.sh <repo>` to see the full evidence picture.
3. Use `bootstrap/repair-system.sh <repo> --dry-run` before mutating a drifted
   repo whenever feasible.
4. Use `bootstrap/heal-system.sh <repo> --source <template-root>` only for safe
   mechanical recovery.
5. Re-run validation and record the real outcome.

## Agent rule

If a requested or inferred repair crosses from mechanical drift into repo-owned
truth, stop treating it as self-healing and move into explicit review or
migration work.

## Bounded auto-correction loop

When a fix is eligible for self-healing, enforce this loop:

1. Detect and classify the failure.
2. Apply only the smallest safe mechanical repair.
3. Re-run targeted validation immediately.
4. Record command/result evidence.
5. Escalate to explicit human-reviewed repair if uncertainty remains after two attempts.
