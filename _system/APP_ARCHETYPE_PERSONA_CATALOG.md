# App Archetype Persona Catalog

This catalog defines template-safe build personas for downstream app generation.

These personas are reusable routing lenses, not app-specific truth for this
parent template repository.

## Universal App Orchestrator

- Purpose: classify unknown requests and choose the right profile + archetype.
- Must do:
  - pick exactly one primary archetype
  - assign agent roles and write scopes
  - enforce runtime and `_system/` separation
  - require validation, installer, and handoff gates

## Archetype Personas

- `web-saas` -> `archetypes/web-saas.md`
- `local-first-desktop` -> `archetypes/local-first-desktop.md`
- `mobile-apk` -> `archetypes/mobile-apk.md`
- `cli-tool` -> `archetypes/cli-tool.md`
- `ai-agent-app` -> `archetypes/ai-agent-app.md`
- `cybersecurity-tool` -> `archetypes/cybersecurity-tool.md`
- `evidence-reporting-app` -> `archetypes/evidence-reporting-app.md`
- `background-check-or-osint-app` -> `archetypes/background-check-or-osint-app.md`
- `finance-budgeting-app` -> `archetypes/finance-budgeting-app.md`
- `home-property-management-app` -> `archetypes/home-property-management-app.md`
- `fullstack-marketplace` -> `archetypes/fullstack-marketplace.md`
- `data-dashboard` -> `archetypes/data-dashboard.md`
- `metasystem-reviewer-app` -> `archetypes/metasystem-reviewer-app.md`

## Routing Rules

- Never emit multiple primary archetypes in one scaffold decision.
- Secondary constraints are allowed only as scoped addenda in `PROJECT_PROFILE.md`.
- If domain intent conflicts with selected archetype, halt and request explicit
  operator confirmation.
