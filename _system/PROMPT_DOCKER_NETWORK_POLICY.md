# Docker Network Policy Prompt Rules

For host port selection, ranges, and collision workflow, read `_system/ports/PORT_POLICY.md` and use `registry/port_governance.yaml` with `tools/check-port-collisions.py` / `tools/preflight_port_scan.py`.

- App containers may publish their own UI/API port to loopback when needed for operator access.
- Internal services such as Redis, Dragonfly, Postgres, MinIO, queues, and caches must stay on the compose network by default.
- Compose files must carry healthchecks and restart policies for internal backends.
- Compose overrides that introduce host publishing must explain why the app cannot use the internal network path instead.
