# Port governance templates

Example snippets for authoring `ops/compose/compose.yml` and env files. Replace placeholders with values produced by `ops/install/lib/port_allocator.py` and recorded under `registry/`.

- `compose-loopback-snippet.yml` — publish an app port to loopback only (`127.0.0.1:${HOST_PORT}:${CONTAINER_PORT}`).

Do not commit real host ports without running `tools/check-port-collisions.py` and `tools/preflight_port_scan.py` against the target repo root.
