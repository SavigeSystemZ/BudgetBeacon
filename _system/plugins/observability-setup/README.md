# Observability Setup Plugin

Scaffolds health endpoints, structured logging, and metrics configuration.

## Hooks

- `monitoring.setup` — generates observability scaffolding from project profile
- `bootstrap.post_install` — suggests observability setup after initial install
- `environment.validate` — checks that declared monitoring endpoints are reachable

## What it does

1. Reads `_system/PROJECT_PROFILE.md` for declared ports, services, and health endpoints.
2. Validates that health and readiness endpoints are defined.
3. Checks for structured logging configuration.
4. Reports observability gaps and suggests remediation.

## Configuration

No additional configuration needed. Reads from the project profile.
