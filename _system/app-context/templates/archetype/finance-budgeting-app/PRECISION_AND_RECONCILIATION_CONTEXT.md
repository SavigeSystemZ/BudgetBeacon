# Precision and Reconciliation Context
Status: TEMPLATE PLACEHOLDER — fill after scaffold.
This file is intentionally app-neutral in the parent AIAST template.
After scaffold into a project-specific repo, replace the sections below
with project-specific truth. Do not copy facts from other apps. Do not
leave this file blank after the first meaningful project setup pass. Do
not write secrets here.

## What this file is

App-specific context for precision and reconciliation, part of the `finance-budgeting-app` archetype context pack
(`_system/archetypes/finance-budgeting-app.md`). Project-specific truth, derived from
`PRODUCT_BRIEF.md` and `app/`.

## Fill this in

- The money representation (integer minor units, not floats) and rounding rules.
- How balances are reconciled.
- The invariants that must always hold across accounts.
- How discrepancies are detected and surfaced.

## Evidence that belongs here

Concrete, checkable facts — not aspirations. Never secrets, tokens, or
credentials.

## Related

- `_system/archetypes/finance-budgeting-app.md`
- `_system/APP_CONTEXT_FILE_MATRIX.md`
- `_system/APP_SPECIFIC_CONTEXT_AUTHORING_STANDARD.md`
