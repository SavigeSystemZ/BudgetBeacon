# fill-app-context

Generate and fill this repo's **app-specific context pack** — the durable
app-specific truth that makes the neutral archetype packs concrete for *this*
app.

Authoritative for every agent (Claude, Codex, Cursor, Windsurf, Gemini,
Copilot, Aider, Cline, Continue, DeepSeek, PearAI, local) — see
`_system/HOST_ADAPTER_POLICY.md`. Governed by
`_system/APP_SPECIFIC_CONTEXT_AUTHORING_STANDARD.md` and
`_system/APP_CONTEXT_FILE_MATRIX.md`.

## Precondition (do not skip)

Run `bash bootstrap/check-app-definition-state.sh .` first.

- `meta_template` → STOP. This is the meta-system template, not an app repo.
  No app-context is filled here (template neutrality).
- `blank_app_undefined` → STOP. The app is not defined yet. First define it
  with the operator (`_system/APP_REPO_IDENTITY.md`).
- `app_defined` → proceed.

## Steps

1. **Select the archetype.** Classify the app through
   `_system/APP_ARCHETYPE_ROUTING_MATRIX.md`; pick exactly one primary
   archetype id. Record it in `_system/app-context/APP_IDENTITY.md` and
   `_system/PROJECT_PROFILE.md`.
2. **Generate the pack.**
   `bash bootstrap/generate-app-context-pack.sh . --archetype <id>` —
   materializes the selected archetype's context files into
   `_system/app-context/archetype/`. The 8 universal files already ship in
   `_system/app-context/`.
3. **Fill every file** with project-specific truth, per
   `_system/APP_SPECIFIC_CONTEXT_AUTHORING_STANDARD.md`: concrete,
   evidence-bearing, cross-referenced, no secrets. Generic filler means the
   file is not done.
4. **Validate.** `bash bootstrap/validate-app-context-files.sh . --strict`,
   then `bash bootstrap/system-doctor.sh` — resolve any awareness/registry
   follow-through for the new files.
5. **Record it** in `WHERE_LEFT_OFF.md`: the app-context pack was filled and
   when to re-run this (archetype change, or a major domain/stack shift).

## Re-run policy

Re-run after the archetype changes (regenerates the archetype files) or
whenever the app's domain materially shifts, so the context never drifts
behind the app.
