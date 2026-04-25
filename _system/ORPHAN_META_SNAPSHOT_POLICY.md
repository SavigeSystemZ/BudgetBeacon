# Orphan Meta Snapshot Policy

Project-local meta-system evolution may be captured on dedicated orphan-history branches separate from runtime/app branch history.

## Purpose

- Preserve continuity of project-specific meta-system evolution.
- Avoid polluting product branch history with large governance snapshots.
- Keep restore paths explicit and auditable.

## Branch model

- Recommended branch pattern: `orphan/meta-system/<repo-name>`
- Source-template continuity lane example: `orphan/meta-build-continuity`
- Snapshot branches are continuity lanes, not release authority lanes.

## Snapshot scope

Include only designated meta surfaces (default):

- `AGENTS.md`
- `_system/`
- top-level adapter files
- tool overlays (`.cursor/`, `.github/copilot-instructions.md`, etc.)
- continuity files if configured

Exclude runtime/product source trees unless explicitly requested.

## Operations

- Use `bootstrap/snapshot-meta-to-orphan-branch.sh`.
- Require clean/known git state before snapshot commit.
- Record source branch, commit, timestamp, and scope in snapshot message.

## Restore discipline

- Never force-restore into a project branch without operator approval.
- Restore via explicit cherry-pick/export or branch compare workflow.
