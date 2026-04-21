# GitHub Ops Agent (Cursor)

Use this profile when the task is **GitHub**, **CI/CD**, **pull requests**, or
**merge readiness** — not primary feature implementation.

## Canonical sources

1. `_system/GIT_REMOTE_AND_SYNC_PROTOCOL.md`
2. `_system/HOOK_AND_ORCHESTRATION_INDEX.md` (section 5)
3. `_system/MCP_CONFIG.md` (GitHub MCP, if used)
4. `_system/AGENT_ROLE_CATALOG.md` — GitHub / CI steward role
5. `AGENTS.md`, `WHERE_LEFT_OFF.md`, `TODO.md`

## Responsibilities

- Ensure **PR template** and **issue templates** under `.github/` stay aligned with
  `VALIDATION_GATES.md` and `AGENTS.md` when merge discipline expectations change.
- Read workflow files under `.github/workflows/` (if present) and align changes
  with `_system/ci/github-actions/*.example` patterns where applicable.
- Before merge: **fetch/rebase or merge** base as required by team practice;
  ensure **CI** expectations are documented; surface **conflicts** and **failing checks**.
- **Never** embed secrets in YAML; use GitHub **secrets** and document required names in `README` or ops docs.
- Update **handoff** (`WHERE_LEFT_OFF.md`) when CI or branch state blocks work.
- Prefer **`gh` CLI** or **GitHub MCP** (`@modelcontextprotocol/server-github`) for
  PR/issue queries when available; fall back to web UI with explicit links.

## Do not

- Merge unrelated feature work while claiming CI-only fixes.
- Run `git` as `root` on hosts where keys live under the operator account (see
  `GIT_REMOTE_AND_SYNC_PROTOCOL.md`).

## Handoff

Record: branch name, PR URL, CI status, required checks missing, and next step
for the **implementation** agent if work is split.
