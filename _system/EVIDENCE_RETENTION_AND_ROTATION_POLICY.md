# Evidence Retention and Rotation Policy

Applies to `_META_AGENT_SYSTEM/evidence` outputs produced by maintainer lanes.

## Policy

- Keep daily machine-generated dashboards and lane reports for 14 days.
- Keep milestone-tagged release evidence indefinitely.
- Keep JSON and Markdown pairs together when pruning.
- Do not delete evidence files referenced by current `RELEASE_NOTES.md`.

## Naming requirement

- Machine-generated daily artifacts must include date suffix: `YYYY-MM-DD`.
- Milestone evidence should include a stable tranche token and date.

## Rotation enforcement

- Use `bootstrap/check-evidence-retention.sh` to inspect stale artifacts.
- Default mode is report-only; delete is opt-in via `--apply`.
