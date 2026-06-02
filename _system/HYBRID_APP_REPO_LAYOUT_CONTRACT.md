# Hybrid app repo layout contract

This contract defines the default single-founder layout for app repositories in
the MyAppZ workspace when using a hybrid runtime/meta separation and snapshot
archives.

## Required root layout

Every app must live under one app-scoped parent folder similar to:

- MyAppZ/<AppName>/app-runtime/ - runtime/product code repo
- MyAppZ/<AppName>/app-meta/ - AI/meta/dev-system repo
- MyAppZ/<AppName>/snapshots/ - snapshot archive and manifest store
- MyAppZ/<AppName>/ops/ - shared operational scripts and logs

## Ownership and boundaries

- `app-runtime` holds only product/runtime code and runtime-facing docs.
- `app-meta` holds agent prompts, governance contracts, planning, and developer
  automation that should not ship as app runtime code.
- `snapshots` is append-first archive storage and must not be used as an active
  working tree.
- `ops` is the integration layer used by scripts that coordinate runtime/meta
  git operations and snapshot lifecycle actions.

## Git expectations

- `app-runtime` and `app-meta` are separate private git repositories.
- `snapshots` may be a non-git archive tree or a private snapshot-index repo.
- Do not cross-commit runtime files into `app-meta` or meta files into
  `app-runtime`.

## Recommended snapshot subtree

- MyAppZ/<AppName>/snapshots/archives/
- MyAppZ/<AppName>/snapshots/manifests/
- MyAppZ/<AppName>/snapshots/index/
- MyAppZ/<AppName>/snapshots/restore-sandbox/

## Safety rules

- Never store encryption private keys in app repositories.
- Never publish snapshots unencrypted to non-local remotes.
- Keep operation logs in `.MyAppZ/<AppName>/ops/logs/`.
- Treat snapshot artifacts as immutable once marked `release`.
