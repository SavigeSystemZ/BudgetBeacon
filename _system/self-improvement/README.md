# Self-Improvement (project-local)

This directory holds the working state of the **downstream project-local
self-improvement** loop. See `_system/PROJECT_LOCAL_SELF_IMPROVEMENT_PROTOCOL.md`
for the loop and `_system/SELF_WRITING_BOUNDARY_AND_ROLLBACK.md` for the
boundary.

## Layout

- `proposals/` — open proposals written by `bootstrap/propose-local-self-improvement.sh`.
- `applied/`   — applied proposals plus their reverse patches (rollback
  evidence), written by `bootstrap/apply-local-self-improvement.sh`.
- `rejected/`  — proposals that were rolled back or declined, with the reason.
- `ledger.jsonl` — append-only durable record of applied self-improvements
  (created on first apply).

## These are runtime artifacts

Everything under `proposals/`, `applied/`, `rejected/`, and `ledger.jsonl` is
**repo-local runtime state**. It is gitignored in the parent template,
excluded from `aiaast_print_managed_files`, and is **not** template-managed —
so it never causes registry or awareness drift. Only this `README.md` is a
tracked, managed file.

## Roles

In `parent-template` mode the loop is inert: the parent template evolves via
the maintainer loop (`_system/SELF_IMPROVEMENT_PROTOCOL.md`). In a
`downstream-app` repo the loop is available once the app is defined; the
project-local AIAST copy is yours to tailor, within the boundary contract.
