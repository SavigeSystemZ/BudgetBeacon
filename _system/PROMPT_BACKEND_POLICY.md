# Backend Policy Prompt Rules

- Every backend must declare ownership, role, auth model, persistence requirement, exposure model, and host-port rationale in `docs/security/backend-inventory.md`.
- Redis-class backends must support env-driven `REDIS_URL`, `REDIS_HOST`, `REDIS_PORT`, `REDIS_USERNAME`, and `REDIS_PASSWORD` surfaces when relevant.
- Generated apps must not depend on a shared host Redis or shared host Postgres without an explicit documented exception.
- Port assignments must be recorded in `registry/ports.yaml` and backend ownership in `registry/backend-assignments.yaml`.
