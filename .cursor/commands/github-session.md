# GitHub Session

Use this command to start a **GitHub / CI / merge-readiness** slice.

## Load first

1. `AGENTS.md`
2. `_system/GIT_REMOTE_AND_SYNC_PROTOCOL.md`
3. `_system/HOOK_AND_ORCHESTRATION_INDEX.md` (section 5)
4. `_system/MCP_CONFIG.md` if using GitHub MCP
5. `.cursor/agents/github-ops.md`
6. `WHERE_LEFT_OFF.md`, `TODO.md`

## Do

- Inspect `.github/workflows/` if present; compare with `_system/ci/github-actions/*.example` when adding workflows.
- Check branch sync, PR state, required checks; update handoff with blockers.
- Never commit secrets into YAML.

## Evidence

Record commands run (e.g. `gh pr status`, `git status`) and outcomes in `WHERE_LEFT_OFF.md`.
