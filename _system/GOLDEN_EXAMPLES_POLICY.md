# Golden Examples Policy

The golden example pack gives agents concrete quality-bar references without making a new repo inherit another app's live reality.

## Purpose

- show what strong working files, prompt/governance surfaces, and multi-surface layouts look like
- preserve donor-repo lessons as neutral patterns instead of raw copied truth
- help new agents recover quality quickly after context loss or handoff

## Use this pack when

- bootstrapping a new repo or major subsystem
- writing or upgrading `PLAN.md`, `WHERE_LEFT_OFF.md`, or `_system/PROJECT_PROFILE.md`
- adding or restructuring prompt packs, skills, rules, or MCP policy docs
- evolving AIAST itself

## Safe use rules

1. Treat the example pack as structure and quality guidance only.
2. Rewrite every example into repo-local truth before committing it.
3. Keep app names, ports, providers, paths, product language, and runtime behavior specific to the target repo.
4. Prefer pattern extraction over literal copying.
5. Keep donor provenance in `_TEMPLATE_FACTORY/`; installed repos must not depend on factory-only files.

## Unsafe use

- copying donor runtime code into a different app
- copying donor product facts, operator notes, ports, or release posture verbatim
- using a donor repo as the default shape for every new project
- letting example docs outrank repo-local canonical docs

## Operating model

- `_system/golden-examples/golden-example-manifest.json` is the machine-readable map.
- `_system/golden-examples/PATTERN_INDEX.md` is the human-readable entrypoint.
- `_system/golden-examples/patterns/` holds neutralized donor-pattern guides.
- `_system/golden-examples/working-files/` holds exemplar quality-bar documents.

## Maintenance rule

When the strongest donor repos change materially, refresh the factory scorecard and selection docs first, then update the installed example pack only where the neutralized guidance should actually change.
