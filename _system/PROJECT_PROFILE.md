# Project Profile

Fill this file in immediately after copying the operating system into a real repo. The stronger and more specific this file is, the better every agent will perform.

## After scaffold (customize for your app)

1. Replace every `- App name:` / `- Repo purpose:` style blank with **your** product truth.
2. Keep `_system/` as the agent operating layer; put runtime code outside it (see `AGENTS.md`).
3. If you use governed ports, follow `_system/ports/PORT_POLICY.md` and record bindings under `registry/`.
4. Re-run `bootstrap/validate-system.sh . --strict` after meaningful edits.
5. See `_system/INSTALLER_AND_UPGRADE_CONTRACT.md` for how installs and upgrades preserve app-owned state.

## Completion status

- [ ] Identity filled
- [ ] Runtime boundaries filled
- [ ] Stack filled
- [ ] Components filled
- [ ] Build, packaging, and install filled
- [ ] Mobile and AI filled
- [ ] Validation commands filled
- [ ] Operations and deployment filled
- [ ] Security and compliance filled
- [ ] Observability filled
- [ ] Constraints filled
- [ ] MCP plan filled
- [ ] Canonical docs filled
- [ ] Experience targets filled
- [ ] Release model filled

## Identity

- App name: Budget Beacon
- App id: io.aiaast.budget.beacon
- Desktop entry id: io.aiaast.budget.beacon
- Android application id: io.aiaast.budget.beacon
- Repo purpose: Build Budget Beacon, a budgeting app that helps people track spending against planned monthly budgets and notice budget pressure early.
- Product category: Personal budgeting and spending-awareness app
- Primary users: Individuals and households managing everyday budgets
- Main workflows: Set budget categories and monthly targets; capture or import transactions; review month-to-date spend vs budget; inspect remaining budget and overspending risk
- Primary success criteria: Users can create a budget, record realistic transactions, and understand current budget status from trustworthy totals and category rollups
- Non-goals: Tax preparation, investment advice, or multi-entity accounting in the first phase

## Runtime boundaries

- Runtime code roots:
- Test roots:
- Scripts / tooling roots: tools/
- Packaging / deploy roots: ops/, packaging/, mobile/, ai/
- Infrastructure roots:
- Agent-system root: `_system/`
- No-touch zones:

## Stack

- Primary languages: Python
- Primary frameworks:
- Components: Budget domain model, transaction ledger or import surface, budget dashboard, reporting or summary views
- Datastores:
- Package managers:
- Build tools:
- Runtime environments:
- Supported environments:
- Deployment targets:

## Build and packaging

- Packaging targets:
- Native package targets:
- Universal package targets:
- Packaging manifest paths: packaging/appimage.yml, packaging/flatpak-manifest.json, packaging/snapcraft.yaml
- Installer commands: ops/install/install.sh, ops/install/repair.sh, ops/install/uninstall.sh, ops/install/purge.sh
- Signing identity: Release owner placeholder; replace before shipping signed artifacts
- Minimum runtime versions:
- System dependencies:
- Build entrypoints:
- Release artifacts:

## Validation commands

- Format:
- Lint:
- Typecheck:
- Unit tests:
- Integration tests:
- End-to-end or smoke:
- Build:
- Install / launch verification:
- Packaging verification:
- Visual regression or design smoke:
- Security or policy checks: bootstrap/scan-security.sh /home/whyte/.MyAppZ/BudgetBeacon

## Mobile and AI

- Mobile targets:
- Android module path: mobile/flutter/
- Mobile release artifacts:
- Mobile build flavors:
- LLM config path: ai/llm_config.yaml
- Default LLM provider:
- Chatbot surfaces: CLI REPL, REST endpoint, GUI side panel when a UI exists
- Command bus or action registry:
- Local documentation sources:

## Operations and deployment

- Default ports:
- Default port range:
- Bind model:
- Required background services:
- Service model:
- Migration model:
- Database mode:
- Container runtime preference:
- Service account model:
- Required env vars:
- Optional providers:
- Known degraded modes:
- Backup location:
- Filesystem layout:
- Environment files:
- Reverse proxy or ingress:

## Security and compliance

- Safety / compliance: Avoid framed output that could be mistaken for financial, tax, or investment advice
- Security: Treat user financial records as sensitive application data and avoid overclaiming any storage or sync protections before they exist
- Secret handling: Keep provider keys and integration credentials out of repo files and example configs
- Data classification: Personal financial activity and budget data should be treated as sensitive user data
- Audit or retention requirements:
- Threat model doc:

## Observability

- Structured logging surface:
- Metrics surface:
- Health or readiness surface:
- Tracing or profiling surface:
- Alerting or dashboards:

## Constraints

- Performance:
- UI / design: The first visible surface should feel trustworthy, readable, and finance-specific rather than like a generic admin dashboard
- Accessibility expectations: Strong numeric readability, clear color contrast, keyboard reachability, and non-color-only budget status signals
- Data integrity: Budget totals, category balances, and reporting periods must reconcile predictably
- Release / packaging:
- Repo workflow:
- Compatibility requirements:

## MCP plan

- Project-scoped servers:
- User-level shared servers:
- Read-only defaults:
- Elevation rules:
- Servers to avoid:

## Canonical docs

- Product spec:
- Architecture:
- Data model:
- Runbook:
- Standards:
- Threat model:
- Additional design docs:

## Experience targets

- Visual quality bar: Calm, polished, high-signal finance UI with intentional hierarchy
- Interaction quality bar: Quick budget review, clear transaction flows, and obvious state transitions
- Performance quality bar: Core budget status and transaction views should feel immediate on normal datasets
- Accessibility expectations: Numeric clarity, keyboard support, strong contrast, and explicit error states
- Device targets:
- Brand or tone constraints: Trustworthy, calm, practical, and precise

## Release model

- Environments:
- Branch strategy: main for runtime code, system for copied AIAST updates, optional short-lived feature branches
- Rollout method:
- Backout method:
- Release signoff:
- Post-release verification:

## High-value conventions

- Naming conventions:
- Module boundary rules:
- Logging rules:
- Testing rules:
- Handoff expectations:
- Documentation update expectations:
