# Backend Inventory

Update this file whenever a backend is added, removed, or its exposure/auth model changes.

| Backend | Role | Auth model | Persistence | Exposure | Host port | Rationale |
|---|---|---|---|---|---|---|
| `postgres` | primary database | env-driven credentials | required | internal-only by default | none | Keep off host ports unless an operator tool truly needs direct host access. |
| `redis` | cache / queue / sessions / rate limiting | URL and optional username/password fields | app-defined | internal-only by default | none | Publish to loopback only when a host-native workflow cannot use the container network. |

## Change checklist

- Update `registry/ports.yaml` if any host port is reserved.
- Update `registry/backend-assignments.yaml` with owner path and exposure model.
- Add validation and rollback steps in the matching security docs.
