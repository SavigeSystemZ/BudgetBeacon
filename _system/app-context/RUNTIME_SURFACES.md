# Runtime Surfaces
Status: TEMPLATE PLACEHOLDER — fill after scaffold.
This file is intentionally app-neutral in the parent AIAST template.
After scaffold into a project-specific repo, replace the sections below
with project-specific truth. Do not copy facts from other apps. Do not
leave this file blank after the first meaningful project setup pass. Do
not write secrets here.

## What this file is

App-specific context for this app's runtime surfaces — a universal app-context file every
AIAST app fills. Project-specific truth, derived from `PRODUCT_BRIEF.md`
and `app/`.

## Fill this in

- The processes and services this app runs and what each does.
- Ports and bind addresses (loopback vs published) per the port policy.
- Background jobs, schedules, and queues.
- External runtime dependencies the app needs to start.

## Evidence that belongs here

Concrete, checkable facts — not aspirations. Never secrets, tokens, or
credentials.

## Related

- `_system/APP_CONTEXT_FILE_MATRIX.md`
- `_system/APP_SPECIFIC_CONTEXT_AUTHORING_STANDARD.md`
