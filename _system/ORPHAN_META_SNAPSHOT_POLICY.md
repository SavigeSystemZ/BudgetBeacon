# Orphan Meta Snapshot Policy

Each downstream AIAST app maintains a **cloud-safe backup of its
app-specific meta-system** on a dedicated orphan branch in *its own*
git remote. The branch has no shared history with `main`, so a force
push or rewrite on `main` cannot lose meta-system state, and the
orphan can be cloned independently for forensic review.

This policy applies to **downstream apps only**. The AIAST parent
template (`_system/.aiast-role.json#/role == "parent-template"`) MUST
refuse orphan snapshots. The template's own meta-system is governed by
its own repository; orphan snapshots are an app-scope feature.

## Purpose

- **Preserve continuity** of project-specific meta-system evolution
  even when the app's `main` history is rebased, force-pushed, reset,
  or accidentally rewritten.
- **Provide a cloud copy** without polluting product branch history
  with large governance snapshots.
- **Keep restore paths explicit and auditable** — orphan branches are
  read-only references operators consult; they are never merged into
  `main`.

## Branch model

- **Default branch name**: `meta-snapshot/<app_slug>` (kebab-case slug
  from `_system/app-local-namespace.json#/app_slug`).
- **Legacy / alternate**: `orphan/meta-system/<repo-name>`,
  `orphan/meta-build-continuity` are still recognised as continuity
  lanes for older repos. Tools accept both via `--branch`.
- Snapshot branches are **continuity lanes**, not release-authority
  lanes. Never merged into `main`. Never auto-deployed from.

## Snapshot scope

Default include set (the "app-specific meta-system"):

| Path | Why |
|---|---|
| `AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `WINDSURF.md`, `DEEPSEEK.md`, `PEARAI.md`, `LOCAL_MODELS.md`, `CURSOR.md`, `COPILOT.md`, `AIDER.md`, `AGENT_ZERO.md`, `.cursorrules`, `.windsurfrules`, `.aider.conf.yml`, `.continuerules`, `.clinerules`, `.cursor/`, `.github/copilot-instructions.md` | host-adapter surface; rehydrates a working agent fleet |
| `_system/` | the project-local system layer |
| `_META_AGENT_SYSTEM/` (if present) | app-builder meta-orchestration that some downstream apps carry |
| `_system/app-local-namespace.json` | identity (`app_id`, `app_uuid`) — load-bearing for recovery |
| `_system/.aiast-role.json` | role sentinel (always `downstream-app` for a snapshot — refused otherwise) |
| `_system/agent-state/audit/`, `_system/agent-state/quarantine/` (if present) | forensic state that *belongs* with the meta-system snapshot |
| `_system/mcp/instances/`, `_system/mcp/runtime/mcp-server-provenance.jsonl` (if present) | MCP isolation history per S4/S5 |

**Explicit exclude set:**

- Runtime product source (`src/`, `app/`, `lib/`, `pages/`, etc.)
- Dependencies (`node_modules/`, `.venv/`, `vendor/`, ...)
- Build artefacts (`dist/`, `build/`, `target/`, `.next/`, ...)
- Secrets-bearing files (`_system/mcp/local-overrides/` content other
  than `README.md` and `.gitignore`)
- `.git/` (obvious; included for completeness)

## Safety contract

The snapshot tool MUST:

1. Refuse when `_system/.aiast-role.json#/role == "parent-template"`
   with refusal code `parent_template_refusal`.
2. Refuse when no app-local-namespace record exists yet
   (`namespace_missing`).
3. Operate on the git object database only — never `checkout`,
   `reset --hard`, or otherwise mutate the working tree. Use
   `git hash-object`, `git mktree`, `git commit-tree`,
   `git update-ref`.
4. Be idempotent: if the tree to snapshot is identical to the orphan
   branch tip, exit ok with `unchanged=true` and emit no new commit.
5. Emit a JSON envelope on stdout (under `--json`) compatible with
   `_TEMPLATE_FACTORY/validate-script-json-envelopes.sh`.
6. Push only when explicitly requested (`--push`) and a remote exists.
7. Never touch any branch other than the configured snapshot branch.

## Operations

```
bootstrap/snapshot-meta-to-orphan-branch.sh <repo-root> \
    [--branch meta-snapshot/<slug>] \
    [--push|--no-push] \
    [--remote origin] \
    [--include path ...] \
    [--exclude glob ...] \
    [--dry-run] \
    [--json]
```

Defaults: `--no-push` (operator must opt-in); `--remote origin`;
branch derived from `app_slug`.

Run cadence (recommended, not enforced):

- Before any destructive maintenance (rebase, force-push, history
  rewrite) on `main`.
- After major scaffold operations (host-adapter sync, profile
  promotion, fleet rollout).
- Nightly via host scheduler for active projects.

## Recovery discipline

To restore from an orphan snapshot:

1. `git fetch <remote> meta-snapshot/<slug>:meta-snapshot/<slug>`
2. `git worktree add ../recover meta-snapshot/<slug>` (do NOT
   `checkout` into the active working tree).
3. Inspect, cherry-pick, or `git restore --source` selected files
   back into the working branch.
4. Never `git merge` an orphan branch into `main` — that creates
   shared history and defeats the purpose. Always copy files
   selectively.

## Telemetry

Every snapshot commit message follows the template:

```
chore(meta): snapshot <branch> at <ISO-8601>

source_main_commit: <sha>
source_branch:      <name>
include_paths:      <count>
tree_sha:           <sha>
app_id:             <app_id>
```

This lets `git log meta-snapshot/<slug> --pretty=fuller` reconstruct
the chain of meta-system states without consulting any external store.

## Anti-policy

- **Never** run the snapshot tool inside the AIAST parent template.
  The role-sentinel gate enforces this; if it ever fires in CI
  against the template, that's a P0 bug.
- **Never** push the orphan branch as part of the same operation
  that pushes `main` — the orphan should be a separate intent.
- **Never** add the orphan branch to default-fetch refspecs;
  consumers explicitly request the snapshot.

## Cross-references

- `bootstrap/snapshot-meta-to-orphan-branch.sh` — the implementation.
- `_TEMPLATE_FACTORY/smoke-orphan-meta-snapshot.sh` — acceptance.
- `_system/APP_LOCAL_NAMESPACE_CONTRACT.md` — source of `app_slug`.
- `_system/.aiast-role.json` — role sentinel consulted by the gate.
- `_system/APP_BUILDER_META_SYSTEM_ORCHESTRATION.md` — broader
  meta-system orchestration this slots into.
