# Installer and Deployment Profile
Status: TEMPLATE PLACEHOLDER — fill after scaffold.
This file is intentionally app-neutral in the parent AIAST template.
After scaffold into a project-specific repo, replace the sections below
with project-specific truth. Do not copy facts from other apps. Do not
leave this file blank after the first meaningful project setup pass. Do
not write secrets here.

## What this file is

App-specific context for this app's install and deployment — a universal app-context file every
AIAST app fills. Project-specific truth, derived from `PRODUCT_BRIEF.md`
and `app/`.

## Fill this in

- How the app is installed and run on each target platform.
- The deployment and release steps (see INSTALLER_AND_UPGRADE_CONTRACT.md).
- Rollback and uninstall behavior.
- The environment and configuration the installer needs.

## Evidence that belongs here

Concrete, checkable facts — not aspirations. Never secrets, tokens, or
credentials.

## Related

- `_system/APP_CONTEXT_FILE_MATRIX.md`
- `_system/APP_SPECIFIC_CONTEXT_AUTHORING_STANDARD.md`
