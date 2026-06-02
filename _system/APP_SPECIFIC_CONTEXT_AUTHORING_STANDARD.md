# App-Specific Context Authoring Standard

The meta-system ships **neutral, reusable** archetype packs
(`_system/archetypes/*.md`). This standard defines the **next layer**:
**app-specific context files**, authored inside one downstream app repo, that
make the neutral packs concrete for that app.

App-context is to the archetype packs what the app persona
(`APP_PERSONA_CONTRACT.md`) is to the persona catalog: a tailored, app-local
overlay. It is **modular and additive** — generated on demand, loaded if
present, never required for the meta-system to function.

## What app-context is

App-context captures the durable, app-specific truth an agent needs to build
*this* product well: identity, domain model, runtime surfaces, security and
privacy posture, validation profile, deployment profile, MCP / agent-isolation
profile, quality targets — plus archetype-specific context for the chosen
archetype.

It is **not** live session state (that is `_system/context/*`) and **not** the
neutral standards (those are `_system/` contracts). It is the stable
app-definition layer derived from `PRODUCT_BRIEF.md` and the selected archetype.

## Where it lives

- `_system/app-context/` — the universal app-context files plus the
  `archetype/` directory the generator fills.
- The parent template ships `_system/app-context/` with the universal files as
  **placeholders**, an empty `archetype/`, and a neutral
  `templates/archetype/<id>/` library. Filled app-context exists only in
  downstream repos (template neutrality — `TEMPLATE_NEUTRALITY_POLICY.md`).

`APP_CONTEXT_FILE_MATRIX.md` is the authority for which files exist and where.

## Required header

Every app-context file uses the placeholder header from
`PROJECT_SPECIFIC_PLACEHOLDER_FILE_STANDARD.md`, so `bootstrap/check-placeholders.sh`
tracks it until it is filled.

## Authoring rules

- **Project-specific.** Every filled file states this app's truth. If a section
  reads generically, it is not yet doing its job.
- **Derived, not invented.** Fill from this repo's `PRODUCT_BRIEF.md`, `app/`,
  and chosen archetype — never from another app's reality.
- **Evidence-bearing.** Record concrete facts (entities, surfaces, commands,
  thresholds), not aspirations.
- **No secrets.** Never write credentials, tokens, private keys, or `.env`
  contents into an app-context file.
- **Cross-referenced.** Link the related AIAST contract (e.g.
  `VALIDATION_PROFILE.md` links `VALIDATION_GATES.md`;
  `SECURITY_AND_PRIVACY_CONTEXT.md` links `SECURITY_BASELINE.md`).
- **Validation-aware.** Each file states how its content is checked (which
  validator, which gate).

## Generation and filling

1. After the app is defined and an archetype is selected, generate the pack:

   ```
   bash bootstrap/generate-app-context-pack.sh .
   ```

   It materializes the universal files plus the selected archetype's context
   files from `templates/archetype/<id>/`. It is idempotent and never
   overwrites filled content.

2. Fill the materialized files. The cross-agent command **`fill-app-context`**
   guides an agent through this (authoritative for every agent per
   `HOST_ADAPTER_POLICY.md`).

3. Re-run generation whenever the archetype changes; fill the new files.

## Validation

`bootstrap/validate-app-context-files.sh` checks the pack: in `parent-template`
mode it is a no-op; in a blank app it is advisory; once the app is defined it
verifies the universal and selected-archetype files are present and filled
(non-placeholder). `bootstrap/system-doctor.sh` surfaces it as a warn-tier
signal.

## Anti-patterns

- leaving placeholder prose in place after the app is under construction;
- copying another app's context;
- duplicating a neutral standard instead of linking it;
- storing live session state here (use `_system/context/*`);
- writing secrets.

---
**Authority:** AIAST downstream authoring standard.
**Related:** `APP_CONTEXT_FILE_MATRIX.md`, `APP_ARCHETYPE_ROUTING_MATRIX.md`,
`APP_ARCHETYPE_PACK_AUTHORING_STANDARD.md`, `APP_PERSONA_CONTRACT.md`,
`PROJECT_SPECIFIC_PLACEHOLDER_FILE_STANDARD.md`,
`PROJECT_LOCAL_SELF_IMPROVEMENT_PROTOCOL.md`.
