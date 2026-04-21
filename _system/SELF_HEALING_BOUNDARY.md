# Self-Healing Boundary

AIAST self-healing is conservative repair of known-safe mechanical drift. It is
not permission to erase uncertainty, overwrite repo-owned truth, or silently
"fix" user-directed behavior.

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
