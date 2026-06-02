# App Context File Matrix

This matrix is the authority for **which** app-specific context files an app
needs and **where** each lives. Author them per
`APP_SPECIFIC_CONTEXT_AUTHORING_STANDARD.md`; generate them with
`bootstrap/generate-app-context-pack.sh`.

Two layers: a **universal** set every app fills, and an **archetype** set keyed
to the selected archetype (`APP_ARCHETYPE_ROUTING_MATRIX.md`).

## Universal context (every app)

Twelve universal context concerns. Eight are new files under
`_system/app-context/`; four route to existing authorities — do not duplicate
them.

| Concern | Home | New? |
|---|---|---|
| App identity (name, purpose, users, archetype) | `_system/app-context/APP_IDENTITY.md` | new |
| Domain model (entities, relationships, rules) | `_system/app-context/DOMAIN_MODEL.md` | new |
| Runtime surfaces (processes, services, ports, jobs) | `_system/app-context/RUNTIME_SURFACES.md` | new |
| Security & privacy posture (data classes, threats) | `_system/app-context/SECURITY_AND_PRIVACY_CONTEXT.md` | new |
| Validation profile (this app's concrete checks) | `_system/app-context/VALIDATION_PROFILE.md` | new |
| Installer & deployment profile | `_system/app-context/INSTALLER_AND_DEPLOYMENT_PROFILE.md` | new |
| MCP & agent-isolation profile | `_system/app-context/MCP_AND_AGENT_ISOLATION_PROFILE.md` | new |
| Quality targets (concrete bars for this app) | `_system/app-context/QUALITY_TARGETS.md` | new |
| Project profile (name, stack, scaffold profile) | `_system/PROJECT_PROFILE.md` | existing |
| Architecture invariants | `_system/context/ARCHITECTURAL_INVARIANTS.md` | existing |
| Integration surfaces (external systems) | `_system/context/INTEGRATION_SURFACES.md` | existing |
| Open questions | `_system/context/OPEN_QUESTIONS.md` | existing |

The generator materializes the eight new files. The four existing files are
already part of the scaffold; fill them in place.

## Archetype context (per selected archetype)

Each archetype adds focused context files under `_system/app-context/archetype/`,
materialized from `_system/app-context/templates/archetype/<id>/`. Pick exactly
one primary archetype.

| Archetype id | Archetype context files |
|---|---|
| `web-saas` | `WEB_SAAS_CONTEXT.md`, `API_SURFACE_CONTEXT.md`, `AUTH_AND_TENANCY_CONTEXT.md`, `SAAS_DATA_LIFECYCLE.md` |
| `local-first-desktop` | `DESKTOP_APP_CONTEXT.md`, `LOCAL_DATA_STORAGE_CONTEXT.md`, `DESKTOP_INSTALLER_CONTEXT.md`, `OFFLINE_SYNC_CONTEXT.md` |
| `cli-tool` | `CLI_TOOL_CONTEXT.md`, `COMMAND_SURFACE_CONTEXT.md`, `CLI_DISTRIBUTION_CONTEXT.md` |
| `mobile-apk` | `MOBILE_APK_CONTEXT.md`, `ANDROID_PERMISSION_CONTEXT.md`, `MOBILE_RELEASE_CONTEXT.md`, `MOBILE_PRIVACY_CONTEXT.md` |
| `fullstack-marketplace` | `MARKETPLACE_CONTEXT.md`, `MARKETPLACE_ACTORS_CONTEXT.md`, `TRANSACTION_AND_TRUST_CONTEXT.md`, `MARKETPLACE_DATA_LIFECYCLE.md` |
| `ai-agent-app` | `AI_AGENT_CONTEXT.md`, `MODEL_PROVIDER_CONTEXT.md`, `PROMPT_AND_MEMORY_CONTEXT.md`, `AI_FAILURE_MODE_CONTEXT.md` |
| `data-dashboard` | `DATA_DASHBOARD_CONTEXT.md`, `DATA_SOURCE_CONTEXT.md`, `METRIC_AND_QUERY_CONTEXT.md`, `VISUALIZATION_CONTEXT.md` |
| `cybersecurity-tool` | `CYBERSECURITY_TOOL_CONTEXT.md`, `AUTHORIZED_SCOPE_CONTEXT.md`, `LAB_SANDBOX_CONTEXT.md`, `EVIDENCE_AND_AUDIT_CONTEXT.md` |
| `evidence-reporting-app` | `EVIDENCE_REPORTING_CONTEXT.md`, `REPORT_TEMPLATE_CONTEXT.md`, `CHAIN_OF_CUSTODY_CONTEXT.md`, `EXPORT_AND_REDACTION_CONTEXT.md` |
| `background-check-or-osint-app` | `OSINT_APP_CONTEXT.md`, `AUTHORIZED_SCOPE_CONTEXT.md`, `SOURCE_AND_PROVENANCE_CONTEXT.md`, `PRIVACY_AND_COMPLIANCE_CONTEXT.md` |
| `finance-budgeting-app` | `FINANCE_BUDGETING_CONTEXT.md`, `TRANSACTION_DATA_CONTEXT.md`, `PRIVACY_AND_EXPORT_CONTEXT.md`, `PRECISION_AND_RECONCILIATION_CONTEXT.md` |
| `home-property-management-app` | `HOME_PROPERTY_CONTEXT.md`, `ASSET_AND_DOCUMENT_CONTEXT.md`, `PROJECT_AND_TASK_CONTEXT.md`, `HANDOFF_EXPORT_CONTEXT.md` |
| `metasystem-reviewer-app` | `METASYSTEM_REVIEWER_CONTEXT.md`, `SCORING_RUBRIC_CONTEXT.md`, `REPORTING_CONTEXT.md`, `RECOMMENDATION_ENGINE_CONTEXT.md` |

`AUTHORIZED_SCOPE_CONTEXT.md` is shared by `cybersecurity-tool` and
`background-check-or-osint-app`; the generator writes one copy per repo.

The 13 archetype ids match `_system/archetypes/` and
`APP_ARCHETYPE_ROUTING_MATRIX.md`. Each archetype context file makes a section
of the matching `_system/archetypes/<id>.md` pack concrete for this app.

## Generation and validation

- Generate: `bootstrap/generate-app-context-pack.sh <repo>` — materializes the
  universal new files plus the selected archetype's files; idempotent, never
  overwrites filled content.
- Validate: `bootstrap/validate-app-context-files.sh <repo>` — role/state-aware
  (no-op in `parent-template`, advisory in a blank app, enforced once the app
  is defined).

## Routing rules

- Exactly one primary archetype per app; secondary constraints noted in
  `_system/PROJECT_PROFILE.md` (per `APP_ARCHETYPE_ROUTING_MATRIX.md`).
- If the archetype changes, re-run the generator and fill the new files.
- Archetype context files stay app-specific; never copy them into the parent
  template.

---
**Authority:** AIAST downstream context reference.
**Related:** `APP_SPECIFIC_CONTEXT_AUTHORING_STANDARD.md`,
`APP_ARCHETYPE_ROUTING_MATRIX.md`, `APP_ARCHETYPE_PACK_AUTHORING_STANDARD.md`,
`PROJECT_LOCAL_SELF_IMPROVEMENT_PROTOCOL.md`.
