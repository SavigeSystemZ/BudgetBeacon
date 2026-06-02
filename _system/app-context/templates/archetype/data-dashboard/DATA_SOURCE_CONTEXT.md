# Data Source Context
Status: TEMPLATE PLACEHOLDER — fill after scaffold.
This file is intentionally app-neutral in the parent AIAST template.
After scaffold into a project-specific repo, replace the sections below
with project-specific truth. Do not copy facts from other apps. Do not
leave this file blank after the first meaningful project setup pass. Do
not write secrets here.

## What this file is

App-specific context for the data sources, part of the `data-dashboard` archetype context pack
(`_system/archetypes/data-dashboard.md`). Project-specific truth, derived from
`PRODUCT_BRIEF.md` and `app/`.

## Fill this in

- Each upstream data source and its owner.
- The ingestion cadence and method.
- The schema and freshness guarantees.
- Failure handling for a stale or missing source.

## Evidence that belongs here

Concrete, checkable facts — not aspirations. Never secrets, tokens, or
credentials.

## Related

- `_system/archetypes/data-dashboard.md`
- `_system/APP_CONTEXT_FILE_MATRIX.md`
- `_system/APP_SPECIFIC_CONTEXT_AUTHORING_STANDARD.md`
