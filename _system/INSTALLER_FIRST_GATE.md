# Installer-First Gate

As soon as a downstream app can launch, render, or answer a health check, the
agent must create or update install/setup scaffolding for that app.

## Required Lifecycle

The install surface must support:

- `install`
- `repair`
- `uninstall`
- `purge`
- `status`
- `doctor`
- `logs`
- `open`
- `start`
- `stop`
- `restart`

## Scope

The gate applies to downstream runtime surfaces, not to the parent template
repo as an application. The parent template must ship reusable lifecycle
templates under `bootstrap/templates/runtime/ops/install/`.

## Rules

- Keep lifecycle scripts idempotent where possible.
- Do not write outside the active repo without explicit operator approval.
- Do not edit `.env`; create or refresh example/config templates only.
- Do not delete databases, user data, or unknown files without explicit
  operator approval.
- Prefer local, current-user operations over privileged service changes.

## Enforcement

- `bootstrap/check-installer-first-gate.sh`
- `bootstrap/check-runtime-foundations.sh`
- `bootstrap/generate-runtime-foundations.sh`
