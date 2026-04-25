# Downstream preservation and template sync notice policy

This contract applies to **installed AIAST application repositories** (for example
trees under `~/.MyAppZ/<AppName>/`). It does **not** redefine the master
template product; it tells agents and operators how to avoid breaking
project-specific work when the operating layer is refreshed from source.

## Master template vs downstream project (non-negotiable distinction)

| Location | Role |
| --- | --- |
| `.../_AI_AGENT_SYSTEM_TEMPLATE/TEMPLATE/` (this installable tree when used as **source** for `update-template.sh`) | **Canonical AIAST template master copy** — neutral, reusable operating layer. Not an application product workspace. |
| `~/.MyAppZ/<App>/` (or any clone where the app ships) | **Downstream project repository** — owns product code, product narrative, and repo-local continuity. May carry AIAST-managed files that have been legitimately customized. |
| `_META_AGENT_SYSTEM/` in the AIAST **source** repo | **Maintainer-only meta workspace** — never copied into app installs. |

Agents must treat **working-directory authority** as defined in
`WORKSPACE_AUTHORITY_AND_CONTAINMENT_PROTOCOL.md`: in a downstream app repo,
the repo’s own files win over parent-folder shims.

## What must never be silently destroyed

These surfaces are **preserve-first** for template diff refresh and for
additive installs when the documented flags are used:

- **Stateful / repo-owned continuity:** paths classified as stateful in
  `bootstrap/lib/aiaast-lib.sh` (for example `TODO.md`, `PLAN.md`,
  `WHERE_LEFT_OFF.md`, `PRODUCT_BRIEF.md`, `_system/PROJECT_PROFILE.md`,
  `_system/context/*.md`, and related working files). See also
  `AGENT_INIT_CONVERGENCE.md` and `UPGRADE_AND_DRIFT_POLICY.md`.
- **Product-owned runtime seeds:** materialized copies under `ops/`,
  `apps/`, `packages/`, etc., originating from
  `bootstrap/templates/runtime/` — must not be force-regenerated on refresh
  unless the product team explicitly chooses a repair path (see
  `AIAST_CHANGELOG.md` preserve-first runtime notes).
- **Operator-local experiments:** typically `.ai/` or untracked host shims —
  not authoritative over `AGENTS.md` or `_system/` contracts.

High-risk template changes are further governed by
`TEMPLATE_CHANGE_IMPACT_POLICY.md`.

## Lifecycle entrypoints that may touch downstream files

- `bootstrap/init-project.sh` — first install.
- `bootstrap/install-missing-files.sh` — additive file install (optional
  `--skip-onboarding-seeds` to avoid re-seeding narrative surfaces).
- `bootstrap/update-template.sh` — additive by default; optional
  `--refresh-managed` to align drifted **template-managed** files with the
  chosen source template (review before use on active product branches).
- `bootstrap/scaffold-system.sh` — delegates to init or update-template.
- Factory-only fleet scripts under `_TEMPLATE_FACTORY/` in the **source**
  repository — they invoke the same bootstrap entrypoints; they are not
  installable into app repos.

## Template sync notice file (agent health gate)

After a **successful, non-dry-run** install, missing-files install, or
`update-template` run, bootstrap writes (or overwrites):

- `_system/TEMPLATE_SYNC_NOTICE.md` — human-readable **agent gate** and
  checklist. Content changes whenever bootstrap emits a sync event; it is
  **excluded from `INTEGRITY_MANIFEST.sha256`** like other volatile operator
  surfaces so `verify-integrity` does not false-fail after a successful install.
- `_system/history/template-sync-events.jsonl` — append-only audit trail
  (one JSON object per line). This path is **runtime telemetry**: it is
  treated like other stateful surfaces (omit from managed-file registry
  enumeration and integrity manifest) so strict awareness checks stay aligned
  with on-disk reality.

### Agent launch rule

On cold start in a **downstream** repo, immediately after the checkpoint rule
in `LOAD_ORDER.md`, open `_system/TEMPLATE_SYNC_NOTICE.md`.

- If **`Agent gate: PENDING_HEALTH_CHECK`** appears, complete the checklist
  in that file **before** product feature work. Prefer `system-doctor.sh` and
  `validate-system.sh --strict` when the repo is meant to be contract-clean.
- If **`Agent gate: CLEARED`** or **`NOT_APPLICABLE_TEMPLATE_SOURCE`**, treat
  there as no pending template-rollup health block.

### Clearing the gate

After validation and human review of `git diff`, run:

```bash
bash bootstrap/clear-template-sync-notice.sh .
```

That resets the notice to a **CLEARED** state so the next session does not
repeat the full gate unless another install/update occurs.

## Related documents

- `UPGRADE_AND_DRIFT_POLICY.md` — drift classes and upgrade steps.
- `TEMPLATE_CHANGE_IMPACT_POLICY.md` — risk classes and migration safety.
- `AGENT_INIT_CONVERGENCE.md` — preserve-first downstream operations.
- `REPO_BOUNDARY_AND_BACKUP.md` — backups before broad refreshes.
