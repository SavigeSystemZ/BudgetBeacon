# Repo Boundary And Backup

Keep three layers distinct:

## Runtime layer

- application code
- tests
- scripts
- packaging
- deployment files

## Agent-system layer

- `_system/`
- `AGENTS.md`
- tool entrypoints such as `CLAUDE.md`, `.cursorrules`, and `.github/copilot-instructions.md`
- handoff state files such as `TODO.md`, `FIXME.md`, `WHERE_LEFT_OFF.md`, and `CHANGELOG.md`

## Master-template-only design layer

In the AIAST source repo only:

- a dedicated master-repo-only meta workspace
- maintainer-only planning, research, handoff state, and future system-design files
- files that must not be copied into installed app repos

## Backup / archive layer

- snapshots
- backup branches
- restore bundles
- exported reports or audit packs

## Rules

- Runtime code must not require the agent-system layer to execute.
- Master-template-only design files must stay outside the installable template.
- Backups must not be mixed into active runtime paths.
- Machine-local state and secrets should remain outside the repo whenever possible.
- Backup strategy should preserve recoverability without confusing live code, system files, and archives.
