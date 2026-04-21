# Security Architecture

This generated project defaults to:

- loopback-only publishing for the app entrypoint when host access is needed
- Docker-internal networking for Postgres, Redis, Dragonfly, MinIO, queues, and other internal backends
- env-driven backend endpoints and credentials
- explicit validation and rollback notes committed alongside backend changes

## Default backend topology

| Service | Role | Default exposure | Persistence | Notes |
|---|---|---|---|---|
| `app` | UI/API/runtime entrypoint | loopback host publish allowed | app-defined | Host publishing should stay limited to the operator-facing app port. |
| `postgres` | primary database | internal-only | required | `ops/compose/compose.yml` keeps Postgres off host ports by default. |
| `redis` | cache / queue / sessions / rate limiting | internal-only | app-defined | Only publish to loopback if a host-native workflow truly requires it. |

## Ownership rules

- Record any host-published backend and the reason in `docs/security/backend-inventory.md`.
- Update `registry/ports.yaml` and `registry/backend-assignments.yaml` whenever you reserve or expose a host port.
- Re-run `tools/security-preflight.sh` before merging backend or deployment changes.
