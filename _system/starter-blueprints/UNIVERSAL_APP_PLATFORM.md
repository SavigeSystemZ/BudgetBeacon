# Universal App Platform Blueprint

Use this when the product needs a polished web experience, a durable API, background work, AI-assisted actions, Linux packaging, and an Android client from one repo.

## Expected repo shape

```text
apps/
  web/
  api/
  worker/
shared/
  contracts/
  domain/
  ui/ (optional)
mobile/
  flutter/
packaging/
ops/
  install/
  env/
  compose/
ai/
docs/ (optional)
```

## Architecture rules

- Keep runtime code out of `_system/`.
- Put domain models and API contracts under `shared/` when multiple surfaces consume them.
- Treat `apps/web` and `mobile/flutter` as clients of the same backend contract.
- Keep AI orchestration thin: chatbot intent resolution, permission checks, audit logging, then handoff into domain services.
- Keep installation and packaging logic under `ops/` and `packaging/`, not inside app runtime modules.

## Product quality bar

- Web UI must feel deliberate, branded, and responsive instead of template-generic.
- Mobile UI should share product language with web, but respect Android navigation and touch affordances.
- API must expose readiness, structured logs, request IDs, and clear error contracts.
- Background jobs and AI actions must be auditable and idempotent where possible.
- Linux packaging, Android builds, and install flows should all be CI-visible.

## Validation minimum

- Web build, lint, typecheck, and smoke route test
- API unit and integration tests
- Worker smoke execution
- `ops/install/install.sh --help` and `repair.sh --help`
- `bootstrap/check-runtime-foundations.sh`
- Packaging manifest validation
- Android debug build smoke when `mobile/flutter/` is present

## First milestone suggestion

Build one vertical slice that proves the full platform:

1. A polished primary web screen
2. One real API-backed business flow
3. One background job or async task
4. One chatbot intent that calls the same domain action path
5. One Android screen consuming the same backend contract
