# Single-founder git operating system

This protocol defines a safe and repeatable Git/GitHub workflow for one
developer working with multiple AI agents.

## Default model

- The local repo is authoritative.
- GitHub is a private, full mirror of the local repo.
- `main` is the normal working branch and the normal push target.
- Local validation gates protect quality; GitHub reflects the validated local
  result.
- Branches are exception tools, not the standard solo workflow.

For this system, a pile of remote feature/fix/chore branches creates more
coordination burden than value. Prefer one clean local history on `main`,
with clear commits and tags when releases matter.

## Branch policy

- `main`: ordinary development, always locally validated before push.
- Short topic or recovery branch: allowed only when the operator explicitly
  wants isolation, an experiment, a PR, or emergency recovery.
- Long-lived infrastructure target branch: allowed only when the operator
  deliberately maintains a parallel build target such as `apk`, `windows`,
  `ios`, or `cli`; it must keep the same meta-system and shared app code as
  `main`.

Do not create `feat/*`, `fix/*`, `chore/*`, or `hotfix/*` branches by
default. If one is used, merge or abandon it quickly and delete it locally
and remotely.

## Commit format

Use conventional commits with explicit scope:

- `feat(runtime): ...`
- `fix(meta): ...`
- `chore(snapshot): ...`
- `docs(ops): ...`

Commits should be coherent and small enough to revert safely.

## Mandatory command cycle

For substantive work:

1. `git fetch origin main`
2. Confirm local `main` is not behind `origin/main`
3. Run repo validation gates
4. Create checkpoint snapshot when the change is high-risk
5. Commit with a clear message
6. Push `main` to `origin/main`

## Pull and sync rules

- Prefer `pull --rebase` over merge pulls if another machine updated the mirror.
- Never push to stale `main`; fetch before push when a remote exists.
- Never force-push `main`.
- Prune obsolete local and remote topic branches after any exception branch is
  merged or abandoned.

## Merge policy

- Most solo work does not need a merge event; commit directly on `main`
  after local validation.
- If a branch exception is used, rebase it on current `main` before merge.
- Prefer squash merge for noisy iterative branches.
- Delete the branch after merge.

## Failure recovery policy

- If pre-commit or pre-push validation fails:
  - stop push
  - create snapshot checkpoint
  - repair on `main` when practical
  - create a recovery branch only if continuing on `main` would risk losing
    evidence or blocking unrelated clean work
- If merge fails:
  - snapshot current state before conflict resolution
  - resolve conflicts
  - re-run full gates before finalize

## Private remote policy

- GitHub remotes must be private repositories by default.
- The matching remote is `origin` at `git@github.com:<org>/<local-folder>.git`.
- The GitHub repo is a full mirror of the local repo; do not use GitHub as a
  partial export, issue database, project board, or PR factory unless the
  operator explicitly opts into that collaboration mode.
- Keep runtime and meta remotes separate only for an explicitly selected
  hybrid layout. The normal app repo is one repo mirrored to one GitHub repo.

## GitHub CLI policy

Use `gh` only to support the mirror:

- `gh auth status` to diagnose auth.
- `gh repo view <org>/<repo>` to check whether the mirror exists.
- `gh repo create <org>/<repo> --private --disable-issues --disable-wiki`
  to create the matching private mirror.
- `gh repo edit` to keep the default branch at `main`, disable unused GitHub
  surfaces, and enable branch cleanup for exceptional PRs.

Do not use `gh` to create remote-only branches, standing PR workflows,
Projects, Issues, or GitHub-side automation that competes with local
validation.

## Session closure policy

- End substantive sessions with:
  - clean `git status` understanding
  - pushed commits or explicit blocker recorded
  - notes appended to operation ledger
