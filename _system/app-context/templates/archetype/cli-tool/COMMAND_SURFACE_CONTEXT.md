# Command Surface Context
Status: TEMPLATE PLACEHOLDER — fill after scaffold.
This file is intentionally app-neutral in the parent AIAST template.
After scaffold into a project-specific repo, replace the sections below
with project-specific truth. Do not copy facts from other apps. Do not
leave this file blank after the first meaningful project setup pass. Do
not write secrets here.

## What this file is

App-specific context for the command surface, part of the `cli-tool` archetype context pack
(`_system/archetypes/cli-tool.md`). Project-specific truth, derived from
`PRODUCT_BRIEF.md` and `app/`.

## Fill this in

- The subcommands and their flags.
- Configuration-file and environment-variable inputs.
- The stdin, stdout, and stderr contracts.
- Help and version output behavior.

## Evidence that belongs here

Concrete, checkable facts — not aspirations. Never secrets, tokens, or
credentials.

## Related

- `_system/archetypes/cli-tool.md`
- `_system/APP_CONTEXT_FILE_MATRIX.md`
- `_system/APP_SPECIFIC_CONTEXT_AUTHORING_STANDARD.md`
