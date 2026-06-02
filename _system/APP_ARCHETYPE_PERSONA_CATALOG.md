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

## Persona Contract

Every persona routes to an archetype pack that declares:

- app purpose
- required docs
- required runtime surfaces
- recommended stack options
- security/privacy posture
- installer expectations
- port policy
- validation gates
- UI/UX completion requirements where applicable
- fleet roles
- prompt-pack hooks
- benchmark/test-app scenario
- anti-patterns

## Archetype Personas

| Persona | Archetype pack | Primary emphasis |
| --- | --- | --- |
| Web SaaS Architect | `archetypes/web-saas.md` | auth, API, web UX, deployment |
| Local-First Desktop Architect | `archetypes/local-first-desktop.md` | local data, desktop UX, package/install |
| Mobile APK Architect | `archetypes/mobile-apk.md` | Android permissions, mobile UX, APK build path |
| CLI/TUI Tool Architect | `archetypes/cli-tool.md` | command UX, config, testable workflows |
| AI Agent App Architect | `archetypes/ai-agent-app.md` | model policy, prompt safety, tool boundaries |
| Cybersecurity Tool Architect | `archetypes/cybersecurity-tool.md` | authorized use, audit trail, safe defaults |
| Evidence Reporting App Architect | `archetypes/evidence-reporting-app.md` | provenance, report integrity, exportable evidence |
| Background Check / OSINT App Architect | `archetypes/background-check-or-osint-app.md` | privacy, sourcing, evidence attribution |
| Finance / Budgeting App Architect | `archetypes/finance-budgeting-app.md` | sensitive data handling, auditability |
| Home / Property Management App Architect | `archetypes/home-property-management-app.md` | records, reminders, local-first ergonomics |
| Fullstack Marketplace Architect | `archetypes/fullstack-marketplace.md` | roles, listings, payments-ready boundaries |
| Data Dashboard Architect | `archetypes/data-dashboard.md` | data ingestion, visualization, freshness |
| Metasystem Reviewer Architect | `archetypes/metasystem-reviewer-app.md` | governance review, validation evidence |

## Routing Rules

- Never emit multiple primary archetypes in one scaffold decision.
- Secondary constraints are allowed only as scoped addenda in `PROJECT_PROFILE.md`.
- If domain intent conflicts with selected archetype, halt and request explicit
  operator confirmation.
