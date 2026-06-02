# Git remote and sync protocol (AIAST)

This document defines how autonomous agents should treat Git when working inside repos that ship with the AIAST template. It is **not** a substitute for project-specific secrets handling; it describes remotes, identity surfaces, and sync discipline.

## Goals

- Keep GitHub aligned as a faithful full mirror of the local authoritative repo.
- Prefer **SSH** remotes for GitHub (or your host) when that is the operator standard.
- Recover from **lost local state** by pulling from remote, and recover from **unpushed work** by committing and pushing when policy allows.
- Surface **SSH or credential failures** early and escalate to the operator when human auth is required.

## Non-negotiable priority (complete Git work)

**Treat Git sync as blocking work, not optional housekeeping.** If the goal is progress that survives across machines, sessions, or agents, unfinished Git is unfinished work.

- **Session start (when a remote exists):** `git fetch origin main` before large edits, so you know whether the mirror has commits from another machine.
- **Session end (after substantive edits):** `git status` -> commit with a clear message -> validate -> `git push origin main`. Leaving **only** local commits or dirty trees when shared progress was intended is a **handoff failure**.
- **Ownership / elevation:** run all Git and SSH as the operator UNIX user (**`whyte`** here, never `root`). If a tool ran as root and Git reports `Permission denied` on `.git/index`, repair with `sudo chown -R whyte:whyte .git` (or the repo root) and **retry**; do not stop with a broken index.
- **Hooks / CI noise:** prefer fixing hooks or the underlying issue. Use `git commit --no-verify` or `git push --no-verify` **only** when the operator has explicitly allowed that escape hatch for the repo; otherwise document the blocker and still leave the working tree committable.
- **Blocked push or auth:** spend real effort on SSH agent, remotes, and keys; if still blocked, **prompt the operator with the exact error**—do not silently abandon the Git outcome.

## Remote layout (replace placeholders)

Use these placeholders in new repos unless the operator has pinned a concrete profile (below). In the **master AIAST source repo**, `_META_AGENT_SYSTEM/context/OWNER_GIT_REMOTES.md` is the maintainer-only source of truth for this workspace’s GitHub layout.

| Concept | Placeholder | Example pattern |
| --- | --- | --- |
| Primary GitHub user / org | `GITHUB_USER_ORG` | `example-user` |
| Organization for **new application** repositories | `GITHUB_APPS_ORG` | `example-apps` |
| SSH remote for app `my-app` | — | `git@github.com:GITHUB_APPS_ORG/my-app.git` |

**Convention:** New application repositories are created under `GITHUB_APPS_ORG` with repository name equal to the app slug (e.g. app `test` → `GITHUB_APPS_ORG/test`).

## GitHub mirror model (default)

For this AIAST single-developer workflow, GitHub is deliberately simple:

**PRIMARY PRINCIPLE: GitHub is a cloud backup and archival location, not an operational development surface.**

### Core rules

- **One local app repo = one GitHub repo** (full tracked-file copy, not a branch farm).
- **Remote name:** `origin`; **default branch:** `main` (this is the only persistent branch).
- **Remote repo name matches local folder name exactly** (unless operator explicitly chooses a different slug).
- **Push validated local `main` directly to `origin/main`.**
- **GitHub is read-only for agents** (pull/fetch only, except when instructed to push by operator).

### Branch discipline (non-negotiable)

- **Default: single `main` branch only.**
- **Feature/fix/chore branches are FORBIDDEN by default** — no standing branch stacks.
- **Legacy Branch Remediation (Established Applications):**
  - If an agent encounters an already established application that has a different GitHub policy with multiple standing branches:
  - Do your best to merge all branches into `main` so no code is lost.
  - Alternatively, if there is no difference from the local repository to the remote besides the extra branches (i.e., we don't lose any code), wipe out the remote branches and do a fresh commit and push from the local `main` repository.
  - The goal is to strictly establish the single `main` branch GitHub policy without losing any code.
- **Exception cases (require operator approval):**
  - Emergency recovery (local corruption; recover from remote copy).
  - Operator-approved experiment (temporary; must be merged or deleted within the same session).
  - True multi-person collaboration (rare; merge or abandon immediately after the collaboration ends).
- **When a branch is created (exceptional case):**
  - Merge or delete the branch before ending the session.
  - Do NOT leave branches hanging for "future work" or "optional features."
  - Do NOT use branches as a substitute for feature flags or partial deployment.
  - Validate locally; if validation passes, merge to `main` and delete the branch.

### CI/PR/status checks

- **Do NOT require PRs** for solo work. GitHub PRs are NOT a development gate.
- **Do NOT enable protected-branch rules** that block pushing to `main`.
- **Do NOT enable remote CI gates** that require approval before merging to `main`.
- **Local validation is the gate** — if tests pass locally, the code is ready for `main`.
- GitHub Actions, branch protection, and required checks are allowed but **not mandatory** and **not blocking**.

### GitHub as archive and mirror only

- Keep GitHub **private** by default.
- Disable Wiki, Projects, and Issues unless the operator wants GitHub to become an active collaboration surface.
- Annotated tags are allowed for release milestones (e.g., `v1.0.0`, `release-2026-01`).
- **Tags are NOT alternate development streams** — they are archival markers only.
- If the local repo is lost, clone from GitHub to recover the full state (mirrors the local `main` exactly).

### Cross-machine workflows

The only meaningful concern with this model is cross-machine concurrency:
- **Before starting work on another machine:** `git fetch origin main` to check for unpushed commits.
- **If local and remote differ:** reconcile locally, commit, validate, then `git push origin main`.
- That is still a mirror workflow, not a reason to introduce standing branch stacks.

## Enforcement and validation

These scripts validate Git discipline:

- **`bootstrap/check-git-discipline.sh`** (added via meta-sync gate):
  - Detects standing feature/fix/chore branches and reports them as violations.
  - Exception: branches approved by operator are documented and whitelisted.
  - Fails if `main` is not the default branch.
  - Fails if protected-branch rules block pushing to `main`.
  - Reports success: `git_discipline_ok`.

## Branch lifecycle

When a temporary branch is created:

1. **Before ending the session:**
   - Merge the branch to `main`: `git merge <branch> --ff-only` or `--no-ff` (operator choice).
   - Delete the local branch: `git branch -D <branch>`.
   - Delete the remote branch: `git push origin --delete <branch>`.
   - Validate: `git branch -a` shows no standing branches.

2. **If the session is interrupted:**
   - Document the branch in a handoff note (e.g., `WHERE_LEFT_OFF.md`).
   - Mark the branch with an annotation comment or prefix (e.g., `wip/`, `review/`).
   - On resume, merge or delete the branch before continuing.

3. **Never leave the session with:**
   - Unmerged feature/fix branches.
   - Uncommitted work on the branch.
   - Stale branches from previous sessions.

### Operator profile (SavigeSystemZ / MyAppZ workspace)

This subsection is maintained for **Michael Spaulding**’s workspace. Forks for other operators should replace these values and optionally delete this section. Full maintainer detail (including **local directory name = org repo name**) lives in the master repo at `_META_AGENT_SYSTEM/context/OWNER_GIT_REMOTES.md` (not installable).

| Field | Value |
| --- | --- |
| GitHub username (primary account) | `SavageO13` |
| Organization for **new** app repositories | `SavigeSystemZ` |
| Git `user.name` | Michael Spaulding |
| Git `user.email` | mtspaulding87@gmail.com |
| Transport | **SSH** |
| UNIX login for Git / SSH on this machine | **`whyte`** — GitHub SSH auth and keys are tied to this account |

**Naming:** On this operator’s machine, app roots live under `~/.MyAppZ/<LocalRepoName>`. New GitHub repos for those apps are **`SavigeSystemZ/<LocalRepoName>`** (name matches the folder **exactly**), unless the folder name is not a valid repo name—then set remotes manually.

**Example SSH remote** for an app whose directory name is `<ProjectX>`:

```text
git@github.com:SavigeSystemZ/<ProjectX>.git
```

Legacy or personal repos may still use `SavageO13/<repo>`; always confirm with `git remote -v` before changing remotes.

## Identity surfaces (commit metadata)

Git **user.name** and **user.email** must match the operator’s published identity for that machine or repo. Do **not** invent identities. Typical sources:

- Repo-local `git config user.name` / `user.email`
- Global `~/.gitconfig`
- Environment or credential helper where the operator has already configured them

Agents must **not** commit secrets, tokens, or private keys. SSH private keys stay in the operator’s SSH agent or secure storage, never in the repo.

## Authentication

- **Preferred:** SSH (`git@github.com:ORG/repo.git`). Verify with `ssh -T git@github.com` (or your host) when diagnosing failures.
- **HTTPS + credential helper:** Acceptable only where the operator has explicitly configured it.

### OS user for Git and SSH (this workspace)

Run **`git`**, **`ssh`**, and any **credential / agent** interaction as the operator’s normal login — here **`whyte`**. Do **not** rely on **`root`** for `git push`, `git fetch`, or `ssh -T git@github.com`: keys, `~/.ssh`, and `ssh-agent` are for the user account that owns the workspace, and GitHub will reject or never see the right identity when invoked as root.

If an automated or elevated session must trigger Git, wrap commands explicitly, for example:

```bash
sudo -u whyte -H bash -lc 'cd /path/to/repo && git status'
```

### When push/pull fails

1. Read the error (auth denied, host key, permission, network).
2. If the effective user is **`root`**, retry as **`whyte`** (see above) before deeper diagnosis.
3. Check `git remote -v` points at the intended org/repo.
4. For SSH: confirm agent (`SSH_AUTH_SOCK`), key loaded, and `~/.ssh/config` host aliases if used — under **the same UNIX user** that owns the repo.
5. Retry with explicit `GIT_SSH_COMMAND` or verbose `ssh -v` only in a safe, non-logging way.
6. If the failure requires passphrase entry, unknown key, or org permission changes, **stop and prompt the operator** with the exact error and the remote URL.

## Sync discipline for agents

Treat the remote as **shared truth** alongside the local tree: keep them aligned whenever work is meant to survive across machines or agent sessions.

After substantive edits:

1. `git status` — review scope.
2. If the remote may have newer work: `git fetch` and reconcile (`git pull --rebase` or merge per project rules) before pushing.
3. Commit with a **clear message**; follow project conventions if present.
4. `git push` to the tracked upstream branch.

## End-of-prompt closure requirement

For any substantive session, git closure is mandatory before claiming completion:

1. run `git status` and confirm scope;
2. commit coherent completed work when changes are intended to persist;
3. push when policy and auth allow;
4. if blocked, record exact error, attempted remediation, and next action in handoff/context files.

A session that skips this closure without a documented blocker is incomplete.

If **local files were lost** but commits exist on the remote: recover with `git fetch` and `git checkout` / `git reset` / `git restore` as appropriate to match `origin/<branch>` after confirming you are not discarding unpushed work (`git log origin/HEAD..HEAD`).

If **unpushed local commits or uncommitted work** should not be lost: commit and push (when policy allows) so the remote holds the latest state.

If **remote is empty** or the branch does not exist yet: create the repository under the operator’s apps org (for this workspace typically `SavigeSystemZ/<app-slug>`; otherwise `GITHUB_APPS_ORG/<app-slug>`), add `origin` over **SSH**, and push the initial branch.

### No-repo bootstrap (SavigeSystemZ standard)

When a local app repo has no configured remote or the GitHub repo does not exist yet, agents must use this flow:

1. Derive `app_slug` from the local parent directory name (`basename "$PWD"`).
2. Enforce one-word naming for new repos: no spaces or path separators. If the local directory contains spaces, stop and ask the operator for the canonical one-word slug.
3. Create the repo in the org namespace as `SavigeSystemZ/<app_slug>` (not personal namespace) using SSH transport.
4. Add/set `origin` to `git@github.com:SavigeSystemZ/<app_slug>.git`.
5. Push `main` with upstream tracking (`git push -u origin main`). If the
   repo is still on `master`, rename locally to `main` first only when the
   operator agrees; otherwise push the current default and record the
   exception.
6. Verify with `git remote -v` and `git status -sb`.

Recommended command (run as `whyte`):

```bash
app_slug="$(basename "$PWD")"
gh repo view "SavigeSystemZ/${app_slug}" >/dev/null 2>&1 || \
  gh repo create "SavigeSystemZ/${app_slug}" --private --disable-issues --disable-wiki
git remote get-url origin >/dev/null 2>&1 \
  && git remote set-url origin "git@github.com:SavigeSystemZ/${app_slug}.git" \
  || git remote add origin "git@github.com:SavigeSystemZ/${app_slug}.git"
git push -u origin main
gh repo edit "SavigeSystemZ/${app_slug}" \
  --default-branch main \
  --enable-projects=false \
  --enable-wiki=false \
  --enable-issues=false \
  --delete-branch-on-merge
```

Preferred AIAST wrapper:

```bash
bash bootstrap/gitops.sh mirror --create --push --configure
```

If **SSH authentication or network** blocks fetch/push: diagnose (`ssh -T git@github.com`, `git remote -v`, agent/keys). Retry after fixing keys, `ssh-agent`, or `~/.ssh/config`. If the problem requires passphrase entry, new key enrollment, or org permissions, **stop and prompt the operator** with the exact error text and remote URL.

## Branching

Default to `main` and keep it as the normal working branch. Do not create
topic branches by default for solo work, and do not rename the default
branch without explicit operator approval. Short branches are exception
tools, not the standard workflow.

## Release tags (AIAST source template repository)

The master AIAST source repo uses **annotated tags** (for example `v1.21.0`) to mark installable template milestones. After `git fetch origin --tags`, you can `git checkout v1.21.0` or `git switch --detach v1.21.0` in that clone to pin the **source** tree used for `bootstrap/update-template.sh --source <path-to-TEMPLATE>`.

See `UPGRADE_AND_DRIFT_POLICY.md` (**Pinning the source template (release tags)**) and `RELEASE_NOTES.md` / `AIAST_CHANGELOG.md` for the tag that matches the version you are adopting.

## Related template files

- `HANDOFF_PROTOCOL.md` — handoff quality including branch and validation state
- `REPO_BOUNDARY_AND_BACKUP.md` — backups and boundary rules
- `SECURITY_REDACTION_AND_AUDIT.md` — never commit secrets
