# AI Failure Mode Context
Status: TEMPLATE PLACEHOLDER — fill after scaffold.
This file is intentionally app-neutral in the parent AIAST template.
After scaffold into a project-specific repo, replace the sections below
with project-specific truth. Do not copy facts from other apps. Do not
leave this file blank after the first meaningful project setup pass. Do
not write secrets here.

## What this file is

App-specific context for AI failure modes, part of the `ai-agent-app` archetype context pack
(`_system/archetypes/ai-agent-app.md`). Project-specific truth, derived from
`PRODUCT_BRIEF.md` and `app/`.

## Fill this in

- The known failure modes (hallucination, tool misuse, loops).
- The detection signals for each.
- The fallback or guardrail for each failure mode.
- How failures are surfaced to the user.

## Evidence that belongs here

Concrete, checkable facts — not aspirations. Never secrets, tokens, or
credentials.

## Related

- `_system/archetypes/ai-agent-app.md`
- `_system/APP_CONTEXT_FILE_MATRIX.md`
- `_system/APP_SPECIFIC_CONTEXT_AUTHORING_STANDARD.md`
