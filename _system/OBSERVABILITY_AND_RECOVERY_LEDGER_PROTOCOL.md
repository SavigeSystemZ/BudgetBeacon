# Observability and recovery ledger protocol

This protocol defines deterministic operation logging for git and snapshot
lifecycle events and the generation of operator-facing notes.

## Log location

- Primary log: `.MyAppZ/<AppName>/ops/logs/operations.jsonl`
- Derived notes:
  - `.MyAppZ/<AppName>/ops/SESSION_NOTES.md`
  - `.MyAppZ/<AppName>/ops/RECOVERY_LEDGER.md`

## Event contract

Each JSONL event should include:

- `timestamp` (UTC ISO8601)
- `tool` (`gitops`, `snapshotctl`, or `hybrid-git-sync`)
- `command` (subcommand name)
- `status` (`ok`, `warn`, `error`)
- `app_root`
- `repo_role` (`runtime`, `meta`, `hybrid`)
- optional `details` object

## Required event classes

- Git events: `status`, `sync`, `start-branch`, `merge-safe`, `release-cut`,
  `recover`.
- Snapshot events: `create`, `verify`, `encrypt`, `publish`, `catalog`,
  `restore-dry-run`, `restore`.
- Gate events: pre-commit and pre-push validation outcomes.

## Notes generation

- `SESSION_NOTES.md` should summarize recent successful activity.
- `RECOVERY_LEDGER.md` should summarize failures, rollbacks, and restores.
- Notes should reference `snapshot_id`, branch, and commit SHAs where available.

## Audit and privacy

- Never log credentials, secret material, or private keys.
- Store only non-sensitive operational metadata and deterministic IDs.
