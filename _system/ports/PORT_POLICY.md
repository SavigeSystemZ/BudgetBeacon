# Port governance policy

**CRITICAL:** Do not assign host ports ad hoc (for example `3000`, `8080`, or `5432` on the host for databases). Runtime port truth lives under the **repo runtime** tree, not under `_system/`.

## Where truth lives (installed repos)

| Role | Path |
|------|------|
| Policy ranges, reserved lists, defaults | `registry/port_governance.yaml` |
| Mutable project/service bindings (governed allocate) | `registry/port_assignments.yaml` |
| Legacy single-key registry (env-driven allocate) | `registry/ports.yaml` |
| Backend host publish intent | `registry/backend-assignments.yaml` |
| Allocator (legacy env mode + governed mode) | `ops/install/lib/port_allocator.py` |
| Collision check | `tools/check-port-collisions.py` |
| Live bind preflight | `tools/preflight_port_scan.py` |

Reference defaults for template authors (not mutated by apps) live in `_system/ports/default_port_matrix.yaml`.

## Relationship to installer and host validation

For the full agent checklist (early install scaffolds, host testing, when to
re-verify after large sessions), see `../AGENT_INSTALLER_AND_HOST_VALIDATION_PROTOCOL.md`.

## Agent protocol before Docker, Compose, systemd, or desktop launchers

1. **Read governance:** Open `registry/port_governance.yaml` and internalize reserved ports and class ranges.
2. **Classify the service:** Pick one of `internal_only`, `local_ui`, `proxied`, `lan_service`, `public_service`. Default host bind is loopback unless LAN/public is explicitly required.
3. **Allocate:**
   - **Governed multi-service:** `python3 ops/install/lib/port_allocator.py --project <id> --service <name> --class <frontend|backend|admin|memory|ephemeral_dev_pool> --container-port <n> [--exposure internal_only]` with repo cwd or `--root <repo>`.
   - **Legacy single env key:** `python3 ops/install/lib/port_allocator.py ops/env/.env [--key APP_PORT] [--bind-address 127.0.0.1] [--start N] [--end M]`
4. **Preflight:** `python3 tools/preflight_port_scan.py <repo-root>` before applying compose or systemd changes.
5. **Collisions:** `python3 tools/check-port-collisions.py <repo-root>` must report `port_registry_ok`.
6. **Infra:** Do not publish Postgres, Redis, queues, or caches on the host unless the operator explicitly approves; prefer internal compose networks and `PUBLISH_*_PORT=false` patterns in `ops/env/.env.example`.
7. **Ephemeral dev:** For throwaway sessions, omit host port mappings and rely on ephemeral publish only when Docker Compose supports it and the profile allows it.
8. **Manifest updates:** Reflect chosen ports in `registry/port_assignments.yaml` and/or `registry/ports.yaml`, `ops/env/.env`, and `ops/compose/compose.yml` in the same change set.

## Failure handling

If allocation exits with code 1, or `check-port-collisions.py` fails, or preflight reports a bind conflict: stop, report the conflict, and ask for explicit reallocation parameters (different class, range shift, or manual port).

## Contract reminder

`_system/` is the agent operating layer. **Runtime code must not import or depend on `_system/`.** This file instructs humans and agents; executables and registries stay in repo runtime paths above.
