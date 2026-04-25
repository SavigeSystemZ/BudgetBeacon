# Global Redirect Shim Policy

Redirect shims are thin compatibility entrypoints that send tools back to the active project-local authority.

## Allowed shim classes

- Root-level shims under `~/.MyAppZ/` when a host/tool expects parent-level files.
- Tool-global redirect notices in supported host config locations.

## Required shim behavior

- Clearly state non-authority status.
- Point to active repo-local authority (`AGENTS.md` + `_system/`).
- Keep content minimal and path-based.
- Avoid copied policy bodies and avoid tool lock-in.

## Forbidden shim behavior

- Defining independent governance rules.
- Overriding repo-local authority.
- Embedding long canonical rule copies.
- Writing to vendor-managed config files in unsafe ways.

## Install and alignment flow

- Installers:
  - `bootstrap/install-root-redirect-shims.sh`
  - `bootstrap/install-tool-global-redirects.sh`
- Validator:
  - `bootstrap/check-global-shim-alignment.sh`

## Preserve-first rule

When shim targets already exist, backup before replacement and do not mutate unrelated content.
