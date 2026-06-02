# Template operating-layer sync notice

**Agent gate:** PENDING_HEALTH_CHECK

**When (UTC):** 2026-05-28T05:21:37Z
**Event:** update-template
**Refresh-managed from source:** no
**Installed template version marker (`_system/.template-version`):** 1.24.0

## What happened

Bootstrap synchronized this **downstream application repository** with the
canonical AIAST installable template (`TEMPLATE/`). This directory is **not**
the master template copy; treat your pinned template checkout as the source of
operating-layer churn.

## Preserve-first reminder

Stateful / repo-owned surfaces (for example `PRODUCT_BRIEF.md`,
`_system/PROJECT_PROFILE.md`, `_system/context/*.md`, and standard working
files) are protected from template **diff refresh** paths unless you explicitly
chose `--refresh-managed`. If onboarding seeds ran, review narrative files for
unintended edits before committing.

## Health gate — run before product work

1. `bash bootstrap/emit-session-environment.sh .`
2. `bash bootstrap/system-doctor.sh . --strict` (or omit `--strict` once, then tighten)
3. `bash bootstrap/validate-system.sh . --strict` when this repo should be contract-clean
4. Review `git status` and resolve anything unexpected
5. When satisfied: `bash bootstrap/clear-template-sync-notice.sh .`

## Policy

- `_system/DOWNSTREAM_PRESERVATION_AND_SYNC_NOTICE_POLICY.md`
- `_system/UPGRADE_AND_DRIFT_POLICY.md`
- `_system/AGENT_INIT_CONVERGENCE.md`

<!-- machine_json: {"agent_gate":"PENDING_HEALTH_CHECK","ts":"2026-05-28T05:21:37Z","event":"update-template","refresh_managed":false,"installed_template_version":"1.24.0"} -->

