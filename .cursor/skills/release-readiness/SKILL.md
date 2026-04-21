---
name: release-readiness
description: Evaluate whether work is truly ready for checkpoint, milestone completion, or release claims.
---

# Release Readiness

## Authority

1. `_system/VALIDATION_GATES.md`
2. `_system/RELEASE_READINESS_PROTOCOL.md`
3. `CHANGELOG.md`
4. `WHERE_LEFT_OFF.md`

## Evidence checklist

Before any release or milestone claim, verify:

### 1. Validation evidence

- [ ] All relevant validation commands have been run (format, lint, typecheck, test, build).
- [ ] Test results are recorded with command and output.
- [ ] Any failing checks are documented with impact assessment and next step.
- [ ] Coverage has not regressed from the prior baseline.

### 2. Functional completeness

- [ ] All acceptance criteria for the milestone are met.
- [ ] No TODO items remain that are required for the release.
- [ ] Edge cases and error states have been tested, not just the happy path.

### 3. Documentation currency

- [ ] `CHANGELOG.md` is updated with user-visible changes.
- [ ] `RELEASE_NOTES.md` reflects the current release target.
- [ ] `WHERE_LEFT_OFF.md` is current and actionable.
- [ ] API documentation is updated if contracts changed.

### 4. Risk assessment

- [ ] `RISK_REGISTER.md` is current — no new unrecorded risks.
- [ ] `FIXME.md` has no severity-critical open items.
- [ ] No known data-loss or security issues are unresolved.
- [ ] Rollback plan exists for high-risk changes.

### 5. Operational readiness

- [ ] Install and launch verification passes.
- [ ] Required environment variables are documented.
- [ ] No hardcoded paths, credentials, or machine-local assumptions.
- [ ] Packaging or deploy pipeline has been tested if applicable.

## Readiness verdict

Classify as one of:

- **Ready**: All checks pass. No blocking issues. Release can proceed.
- **Ready with caveats**: Minor issues documented and accepted. Release can proceed with noted limitations.
- **Not ready**: Blocking issues exist. List each blocker with severity and required action.

## Output

- readiness verdict (ready / ready with caveats / not ready)
- evidence summary (which checks passed, which failed)
- missing evidence (what was not verified and why)
- unresolved risks with severity
- required next actions before release can proceed
