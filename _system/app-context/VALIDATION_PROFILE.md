# Validation Profile
Status: TEMPLATE PLACEHOLDER — fill after scaffold.
This file is intentionally app-neutral in the parent AIAST template.
After scaffold into a project-specific repo, replace the sections below
with project-specific truth. Do not copy facts from other apps. Do not
leave this file blank after the first meaningful project setup pass. Do
not write secrets here.

## What this file is

App-specific context for this app's concrete validation — a universal app-context file every
AIAST app fills. Project-specific truth, derived from `PRODUCT_BRIEF.md`
and `app/`.

## Fill this in

- The exact commands that build, test, and lint this app.
- The gates that must pass before delivery (see VALIDATION_GATES.md).
- Coverage and quality thresholds for this app.
- How to run the app's smoke check (see VALIDATION_COMMAND_DISCOVERY_PROTOCOL.md).

## Evidence that belongs here

Concrete, checkable facts — not aspirations. Never secrets, tokens, or
credentials.

## Related

- `_system/APP_CONTEXT_FILE_MATRIX.md`
- `_system/APP_SPECIFIC_CONTEXT_AUTHORING_STANDARD.md`
