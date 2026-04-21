# Delivery Gates

Quality gates that must pass before a milestone is considered complete.

This file is installable and repo-neutral by default. After scaffold into a real
repo, replace generic command placeholders with project truth from
`_system/PROJECT_PROFILE.md`.

## Per-milestone checklist

- [ ] Acceptance criteria met for the selected work item
- [ ] Tests added or updated for changed behavior
- [ ] Lint passes (project command from `_system/PROJECT_PROFILE.md`)
- [ ] Typecheck passes (project command from `_system/PROJECT_PROFILE.md`)
- [ ] Unit or integration tests pass for touched surfaces
- [ ] Build passes when runtime code changed
- [ ] Canonical docs updated when behavior or contracts changed
- [ ] No unrelated refactors included
- [ ] Authorization and boundary checks validated where relevant
- [ ] Error handling is explicit (no silent swallow behavior)
- [ ] No secrets or tokens committed
- [ ] Rollback path is documented or clearly defined

## Validation mapping

Use this compact mapping with `_system/VALIDATION_GATES.md`. For a single ordered checklist of bootstrap validators to run before merge, see `_system/SYSTEM_ORCHESTRATION_GUIDE.md` (review and validation order).

- **Docs/system-only work:** consistency + registry/integrity checks
- **Feature work:** lint + typecheck + tests + build
- **Contract/schema work:** feature checks + contract docs updates
- **Install/deploy/packaging work:** runtime launch/smoke and packaging checks
- **Release claim:** all relevant checks green or explicitly degraded with impact

## Security checks

- Dependency risk reviewed for newly introduced packages
- Sensitive data handling reviewed for changed surfaces
- Audit trail/logging behavior reviewed for security-relevant actions
- No PII/secrets emitted in logs or prompt artifacts

## Evidence requirement

Before handoff or release claim, record:

- command executed
- pass/fail result
- scope covered
- report/artifact path if one exists
- what remains unproven

Use `bootstrap/check-evidence-quality.sh` and
`bootstrap/check-working-file-staleness.sh` before meaningful handoff.

## Automated wiring check

Strict validation includes `bootstrap/check-delivery-gate-alignment.sh`, which
confirms this file and related contracts stay discoverable through core index and
load-order docs. If that check fails, see `_system/TROUBLESHOOTING.md`
(**Delivery-gate alignment check fails**).
