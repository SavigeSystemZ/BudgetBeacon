# App Context

This directory holds the **app-specific context** layer — the durable,
app-specific truth that makes the neutral archetype packs concrete for one
app. See `_system/APP_SPECIFIC_CONTEXT_AUTHORING_STANDARD.md` for how to author
it and `_system/APP_CONTEXT_FILE_MATRIX.md` for the full file matrix.

## Layout

- `*.md` (this directory) — the universal app-context files every app fills.
  They ship as placeholders; fill them with project-specific truth after the
  app is defined.
- `archetype/` — the selected archetype's context files, materialized by
  `bootstrap/generate-app-context-pack.sh`. Empty in the parent template.
- `templates/archetype/<id>/` — the neutral context-template library, one set
  per archetype id. The generator copies the selected set into `archetype/`.

## Workflow

1. Define the app and select an archetype (`APP_ARCHETYPE_ROUTING_MATRIX.md`).
2. `bash bootstrap/generate-app-context-pack.sh .` — materialize the pack.
3. Fill the universal files and the materialized archetype files. The
   cross-agent `fill-app-context` command guides this.
4. `bash bootstrap/validate-app-context-files.sh .` — validate.

In the parent template this layer is inert: the universal files stay
placeholders, `archetype/` stays empty, and the template library ships as the
neutral source for downstream generation (template neutrality).
