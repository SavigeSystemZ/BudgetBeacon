# Composer session bootstrap

Use at the start of a Composer-driven multi-file task.

## Load

1. `AGENTS.md`
2. `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`
3. `_system/REPO_OPERATING_PROFILE.md`
4. `WHERE_LEFT_OFF.md`
5. `_system/VALIDATION_GATES.md` (if the task is medium or larger)

## Plan

- State objective, non-goals, and acceptance checks in three to six bullets.
- List files likely to change before editing.

## Execute

- Edit in coherent slices; keep platform-specific assets in `distribution/platforms/*`
  or `packaging/` as appropriate.
- Run repo validation commands after substantive changes.

## Close

- Update `WHERE_LEFT_OFF.md` with evidence (commands + results) if this session
  completed meaningful work.
- If installers or ports changed, note verification steps for each targeted OS.
