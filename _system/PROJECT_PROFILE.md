# Project Profile

Fill this file in immediately after copying the operating system into a real repo. The stronger and more specific this file is, the better every agent will perform.

## After scaffold (customize for your app)

1. Replace every `- App name:` / `- Repo purpose:` style blank with **your** product truth.
2. Keep `_system/` as the agent operating layer; put runtime code outside it (see `AGENTS.md`).
3. If you use governed ports, follow `_system/ports/PORT_POLICY.md` and record bindings under `registry/`.
4. Re-run `bootstrap/validate-system.sh . --strict` after meaningful edits.
5. See `_system/INSTALLER_AND_UPGRADE_CONTRACT.md` for how installs and upgrades preserve app-owned state.

## Completion status

- [x] Identity filled
- [x] Runtime boundaries filled
- [x] Stack filled
- [x] Components filled
- [x] Build, packaging, and install filled
- [x] Mobile and AI filled
- [x] Validation commands filled
- [x] Operations and deployment filled
- [x] Security and compliance filled
- [x] Observability filled
- [x] Constraints filled
- [x] MCP plan filled
- [x] Canonical docs filled
- [x] Experience targets filled
- [x] Release model filled

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

- Runtime code roots: src/, public/
- Test roots: src/__tests__/
- Scripts / tooling roots: tools/
- Packaging / deploy roots: ops/, packaging/, mobile/, ai/
- Infrastructure roots: ops/
- Agent-system root: `_system/`
- No-touch zones: node_modules/, dist/

## Stack

- Primary languages: TypeScript, HTML, CSS
- Primary frameworks: React, Vite, Tailwind CSS
- Components: Budget domain model, transaction ledger, budget dashboard, reporting views
- Datastores: IndexedDB (via Dexie)
- Package managers: npm
- Build tools: Vite, tsc
- Runtime environments: Web Browser, Linux Desktop via PWA and bash runner
- Supported environments: Linux, Modern Web Browsers
- Deployment targets: Local Linux Desktop

## Build and packaging

- Packaging targets: Linux Desktop
- Native package targets: N/A
- Universal package targets: bash runner script (budget-beacon)
- Packaging manifest paths: packaging/appimage.yml, packaging/flatpak-manifest.json, packaging/snapcraft.yaml
- Installer commands: ops/install/install.sh, ops/install/repair.sh, ops/install/uninstall.sh, ops/install/purge.sh
- Signing identity: Local development
- Minimum runtime versions: Node.js 20+
- System dependencies: Node.js, npm, bash
- Build entrypoints: npm run build
- Release artifacts: dist/ directory

## Validation commands

- Format: npm run format (if added)
- Lint: npm run lint
- Typecheck: tsc --noEmit
- Unit tests: npm run test (vitest)
- Integration tests: N/A
- End-to-end or smoke: N/A
- Build: npm run build
- Install / launch verification: ./install.sh
- Packaging verification: N/A
- Visual regression or design smoke: N/A
- Security or policy checks: bootstrap/scan-security.sh .

## Mobile and AI

- Mobile targets: PWA via browser
- Android module path: mobile/flutter/
- Mobile release artifacts: N/A
- Mobile build flavors: N/A
- LLM config path: ai/llm_config.yaml
- Default LLM provider: None (Local App)
- Chatbot surfaces: CLI REPL, REST endpoint, GUI side panel when a UI exists
- Command bus or action registry: N/A
- Local documentation sources: docs/

## Operations and deployment

- Default ports: 5173 (Vite dev server)
- Default port range: 5173-5183
- Bind model: 127.0.0.1
- Required background services: None
- Service model: Local client application
- Migration model: Dexie versioning
- Database mode: Local IndexedDB
- Container runtime preference: N/A
- Service account model: Current User
- Required env vars: None for production
- Optional providers: None
- Known degraded modes: Offline (supported via PWA)
- Backup location: User browser profile
- Filesystem layout: N/A (Browser storage)
- Environment files: .env
- Reverse proxy or ingress: N/A

## Security and compliance

- Safety / compliance: Avoid framed output that could be mistaken for financial, tax, or investment advice
- Security: Treat user financial records as sensitive application data and avoid overclaiming any storage or sync protections before they exist
- Secret handling: Keep provider keys and integration credentials out of repo files and example configs
- Data classification: Personal financial activity and budget data should be treated as sensitive user data
- Audit or retention requirements: User controlled local deletion
- Threat model doc: docs/security/architecture.md

## Observability

- Structured logging surface: Browser console
- Metrics surface: N/A
- Health or readiness surface: N/A
- Tracing or profiling surface: React Profiler / Browser DevTools
- Alerting or dashboards: N/A

## Constraints

- Performance: Sub-second load times via PWA caching
- UI / design: The first visible surface should feel trustworthy, readable, and finance-specific rather than like a generic admin dashboard
- Accessibility expectations: Strong numeric readability, clear color contrast, keyboard reachability, and non-color-only budget status signals
- Data integrity: Budget totals, category balances, and reporting periods must reconcile predictably
- Release / packaging: Bash installer to ~/.local/bin
- Repo workflow: Local single-developer
- Compatibility requirements: Modern browsers (ES modules support)

## MCP plan

- Project-scoped servers: N/A
- User-level shared servers: N/A
- Read-only defaults: N/A
- Elevation rules: N/A
- Servers to avoid: N/A

## Canonical docs

- Product spec: docs/PRD.md
- Architecture: docs/ARCHITECTURE.md
- Data model: docs/DATA_MODEL.md
- Runbook: README.md
- Standards: _system/CODING_STANDARDS.md
- Threat model: docs/security/architecture.md
- Additional design docs: docs/NFR.md, docs/UX_SYSTEM.md

## Experience targets

- Visual quality bar: Calm, polished, high-signal finance UI with intentional hierarchy
- Interaction quality bar: Quick budget review, clear transaction flows, and obvious state transitions
- Performance quality bar: Core budget status and transaction views should feel immediate on normal datasets
- Accessibility expectations: Numeric clarity, keyboard support, strong contrast, and explicit error states
- Device targets: Desktop Web, Mobile Web
- Brand or tone constraints: Trustworthy, calm, practical, and precise

## Release model

- Environments: Local Host
- Branch strategy: main for runtime code, system for copied AIAST updates, optional short-lived feature branches
- Rollout method: Local install.sh
- Backout method: Local uninstall
- Release signoff: Developer testing
- Post-release verification: Manual run of budget-beacon

## High-value conventions

- Naming conventions: CamelCase for components, kebab-case for files
- Module boundary rules: src/components, src/hooks, src/lib
- Logging rules: Console.log only in development
- Testing rules: Vitest for utilities
- Handoff expectations: Update WHERE_LEFT_OFF.md
- Documentation update expectations: Keep docs/ in sync with features
