# Installation Guide

Use generated runtime assets under `ops/` for app installation behavior. `_system/` defines the contract; it is not a runtime dependency.

## Generated commands

- `ops/install/install.sh`
- `ops/install/repair.sh`
- `ops/install/uninstall.sh`
- `ops/install/purge.sh`

## Expected install flow

1. Detect OS, architecture, and package manager.
2. Prefer packaged artifacts from `dist/`.
3. Fall back to source-style deployment if no package exists.
4. Create least-privilege service user and group for system installs.
5. Create app-owned config and data directories with restrictive permissions.
6. Allocate and persist a loopback port in `ops/env/.env`.
7. Generate a hardened `systemd` unit and optional desktop launcher.

## Safety rules

- Never remove shared dependencies automatically.
- Do not downgrade system packages used by other apps.
- Bind to `127.0.0.1` or `::1` by default.
- Preserve user data on repair.
- Make purge opt-in and explicit.

## Repair expectations

`repair.sh` should restore missing env files, units, launchers, and directories without deleting user data.
