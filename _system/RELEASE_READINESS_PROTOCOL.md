# Release Readiness Protocol

Use this when work is being presented as milestone-complete, release-ready, or distribution-ready.

## Required checks

- relevant validation gates passed or explicitly documented
- install or launch behavior verified if affected
- packaging behavior verified if affected
- user-visible or architectural changes captured in `CHANGELOG.md`
- current release framing captured in `RELEASE_NOTES.md`
- active unresolved risks captured in `RISK_REGISTER.md`
- continuity files updated

## Required evidence

- commands run
- output summary
- known limitations
- unresolved risks
- rollback or mitigation note if risk remains
- next post-release verification step if deployment is staged

## Stop conditions

- critical validation failing without documentation
- install or launch path changed but was not exercised
- packaging or release artifact claims without proof
- missing continuity updates after major work
