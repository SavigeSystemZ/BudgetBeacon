# System Build Standard

- Default to secure-by-default scaffolding, not opt-in hardening.
- Keep runtime endpoints env-driven and avoid hardcoded `localhost`, `127.0.0.1`, or shared host services in application code.
- Treat Redis, Dragonfly, Postgres, MinIO, queues, and other internals as owned backends with an explicit service role and exposure model.
- Generate `docs/security/architecture.md`, `docs/security/backend-inventory.md`, `docs/security/validation.md`, and `docs/security/rollback.md` whenever a runtime or deployment surface is added.
- Require validation and rollback steps in the same change set that introduces or changes backend infrastructure.
- Ship **platform-segregated** distribution assets (`distribution/platforms/*`) and operator menus (install, upgrade, repair, uninstall, purge, reset-data where applicable) per `CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md`; reuse governed port tooling from `ports/PORT_POLICY.md` instead of fixed ports.
- As soon as there is a **first runnable launch path**, generate or update installer and distribution scaffolds (`bootstrap/generate-runtime-foundations.sh`, `ops/install`, `distribution/`, `packaging/` as applicable) so the operator can **live-test install and run on a host** while the app is still incomplete.
