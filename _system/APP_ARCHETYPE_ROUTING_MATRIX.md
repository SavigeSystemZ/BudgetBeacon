# App Archetype Routing Matrix

Archetypes map app category intent to required documentation, security posture,
quality gates, and packaging targets.

See `_system/archetypes/` for individual archetype contracts and
`_system/APP_ARCHETYPE_PACK_AUTHORING_STANDARD.md` for required fields.
Each archetype also has an app-specific context set — see
`_system/APP_CONTEXT_FILE_MATRIX.md`.

## Required Routing Output

- archetype id
- required docs
- required validation gates
- packaging targets
- security model expectations

## Expanded Archetype Packs

- `web-saas` -> `_system/archetypes/web-saas.md`
- `local-first-desktop` -> `_system/archetypes/local-first-desktop.md`
- `cli-tool` -> `_system/archetypes/cli-tool.md`
- `mobile-apk` -> `_system/archetypes/mobile-apk.md`
- `fullstack-marketplace` -> `_system/archetypes/fullstack-marketplace.md`
- `ai-agent-app` -> `_system/archetypes/ai-agent-app.md`
- `data-dashboard` -> `_system/archetypes/data-dashboard.md`
- `cybersecurity-tool` -> `_system/archetypes/cybersecurity-tool.md`
- `evidence-reporting-app` -> `_system/archetypes/evidence-reporting-app.md`
- `background-check-or-osint-app` -> `_system/archetypes/background-check-or-osint-app.md`
- `finance-budgeting-app` -> `_system/archetypes/finance-budgeting-app.md`
- `home-property-management-app` -> `_system/archetypes/home-property-management-app.md`
- `metasystem-reviewer-app` -> `_system/archetypes/metasystem-reviewer-app.md`

## Routing Rules

- Always select exactly one primary archetype for initial scaffold.
- Use profile + archetype pairing to determine validator and packaging defaults.
- If workload spans multiple archetypes, keep one primary and list secondary
  constraints in `PROJECT_PROFILE.md`.

