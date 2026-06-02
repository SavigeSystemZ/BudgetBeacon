# forge-app-persona

Generate or refresh this repo's **app-specific world-class persona** — the
expert lens that bolts onto the meta-system so every agent here builds
*this* app at a world-class bar.

Authoritative for every agent (Claude, Codex, Cursor, Windsurf, Gemini,
Copilot, Aider, Cline, Continue, DeepSeek, PearAI, local) — see
`_system/HOST_ADAPTER_POLICY.md`. Governed by
`_system/APP_PERSONA_CONTRACT.md`.

## Precondition (do not skip)

Run `bash bootstrap/check-app-definition-state.sh .` first.

- `meta_template` → STOP. This is the meta-system template, not an app
  repo. No app persona is forged here (template neutrality).
- `blank_app_undefined` → STOP. The app is not defined yet. First define
  it with the operator (`_system/APP_REPO_IDENTITY.md`); do not forge a
  persona for an undefined app.
- `app_defined` → proceed.

## Steps

1. **Evaluate the app.** Read `PRODUCT_BRIEF.md`, the real code under
   `app/`, and any planning docs. Classify it through
   `_system/APP_ARCHETYPE_ROUTING_MATRIX.md` →
   `_system/APP_ARCHETYPE_PERSONA_CATALOG.md` and the matching
   `_system/archetypes/` contract: pick the archetype, its required
   gates, security posture, packaging targets.
2. **Derive the world-class lens for THIS app.** From the brief + archetype
   + chosen stack, determine the domain mastery, stack-idiomatic craft,
   concrete quality bar, app-specific review lenses, anti-patterns, and an
   app-specific definition of done. Be concrete — generic filler means the
   persona is not done.
3. **Write `_system/personas/APP_PERSONA.md`** with exactly the sections
   required by `_system/APP_PERSONA_CONTRACT.md`. Create the file (the
   slot ships empty); overwrite it if refreshing. Keep it plain
   agent-neutral markdown derived only from THIS repo's truth.
4. **Verify it attaches.** Confirm `LOAD_ORDER.md` / `READ_BUNDLES.md`
   already list it as an optional overlay (they do — present-only). Run
   `bash bootstrap/system-doctor.sh`; resolve any awareness/registry
   follow-through for the new file (regenerate the managed surface if this
   repo gates on it).
5. **Record it.** Note in `WHERE_LEFT_OFF.md` that the app persona was
   forged/refreshed and when to re-run this (domain/stack/quality-bar
   change).

## Re-run policy

This is living. Re-run whenever the app's domain, stack, archetype, or
quality bar materially changes so the persona never drifts behind the app.
