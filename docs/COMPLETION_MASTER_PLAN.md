# Budget Beacon — Repo Completion Master Plan

Saved: 2026-04-25
Source: ultraplan session (cloud run failed with stream idle timeout; plan content preserved here for resumption).

---

## 1. Request Mode

- Mode B — Existing Repo Review / Improvement
- Mode E — Execution Prompt Pack
- Mode F — Merge / Precedence Resolution

This is not a greenfield build. Budget Beacon already exists with a repo-local instruction system and a partially built runtime application. The plan below is a **repo-safe completion plan**, not a fresh MVP plan.

---

## 2. Repo Reality Summary

### 2.1 Repo-local instruction layer is present
Repo-local AIAST-style operating layer exists. README and AGENTS.md make repo-local rules binding; agents must load precedence, operating profile, working files, and validation docs before meaningful edits.

### 2.2 Runtime stack is real and broader than early MVP
Root `package.json` shows React/Vite/TypeScript with Dexie/IndexedDB, Recharts, React Hook Form + Zod, Capacitor Android, Electron, Vitest, PWA plugin. Targets web/PWA, Android, desktop.

### 2.3 Navigation and GUI surface are broad
`src/App.tsx` routes: Dashboard Cockpit, Mission Control, Ledger Loops, Income Pool, Pay Path, Stash Map, Debt Center, Tax Taxi, The Vault, Subscriptions Shelf, Insurance Inspect, Beacon Bridge, Credit Snapshot, Reports Arena, System Settings.

---

## 3. Honest Current-State Assessment

### 3.1 Genuinely present
- persistent local Dexie database with multiple financial tables
- dashboard route
- Pay Path CRUD for bills and debts
- Stash Map CRUD for savings goals
- Ledger / transaction entry route
- Credit snapshot entry and charting
- Tax route with record storage and form-draft UI
- Document vault with local blob storage
- Reports route with printable view
- Electron packaging config
- Capacitor Android config
- budget engine and Vitest coverage for budget math

### 3.2 Mocked / simulated / not production-real
- **AI assistant mocked** — `BeaconChatbot.tsx` uses local `setTimeout(...)` with canned logic.
- **Bank sync mocked** — `LedgerRoute.tsx` "Bank Sync" returns hardcoded items after a timeout.
- **Document ingestion mocked** — `DocumentStoreRoute.tsx` "scavenge" returns hardcoded extracted items.
- **Credit fetch/check mocked** — `CreditRoute.tsx` "Bank Fetch" / "Credit Check" are timeout-driven mock generators.
- **Peer sync / Beacon Bridge mocked** — `BeaconBridgeRoute.tsx` simulates handshake/merge after timeout.
- **Export/report partially mocked** — `ReportsRoute.tsx` Export only alerts.

### 3.3 Validation/documentation drift
- `PLAN.md` claims "fully delivered and installed."
- `TODO.md` marks many milestones complete.
- `WHERE_LEFT_OFF.md` says "Mission Ready. Secured. Polished."
- Code shows several advanced features still simulated.

**Repo truth: the app is impressive and broad, but not yet honestly finished.**

---

## 4. Primary Product Goal

> A polished, private-first, easy-to-use but powerful household budgeting application for real daily use by you and your girlfriend, with optional external automation where practical, while remaining trustworthy and not pretending to do things it does not actually do.

Finish line is **not**: maximum gimmick surface, fake AI everywhere, simulated integrations, more labels than substance.

Finish line **is**: every visible major screen genuinely usable; every action button performs a real outcome; every "smart" feature is either real or clearly labeled manual/coming-later; web app polished; Android app polished; data model stable; import/export/recovery trustworthy; bank/document/AI features delivered through realistic phased integration.

---

## 5. Product Direction Decision

**Keep**: Budget Beacon identity, Pay Path, Stash Map, modular concept, local-first baseline, strong visual quality, multi-surface deployment.

**Change**: remove simulated "agentic" theater; replace mock integrations with real architecture; tighten naming/info hierarchy where style competes with usability; define hard MVP-complete vs Phase 2 boundaries; align docs with reality.

---

## 6. Three-Layer Completion Model

- **Layer 1 — Truth & Stability**: honest, stable, testable, internally coherent.
- **Layer 2 — Full GUI Completion**: every route/sub-route usable top to bottom; all controls connected; all empty/error states handled.
- **Layer 3 — Real Integrations**: actual bank import, actual document parsing, actual AI assistant, actual device-sync architecture in controlled phases.

---

## 7. Completion Blueprint

### 7.1 Canonical docs to (re)establish
- `PRODUCT_BRIEF.md`, `PLAN.md`, `ROADMAP.md`, `ARCHITECTURE_NOTES.md`, `DESIGN_NOTES.md`, `TEST_STRATEGY.md`, `RISK_REGISTER.md`, `WHERE_LEFT_OFF.md`
- Add: `docs/GUI_COMPLETION_MAP.md`, `docs/INTEGRATIONS_STRATEGY.md`, `docs/ANDROID_POLISH_CHECKLIST.md`, `docs/WEB_POLISH_CHECKLIST.md`, `docs/DATA_IMPORT_AND_SYNC_STRATEGY.md`, `docs/AI_ASSISTANT_STRATEGY.md`

### 7.2 Architecture target
- **Core**: local-first data model, trusted budget engine, complete CRUD, reporting/recovery.
- **Integration adapters**: bank import, document ingestion, AI assistant provider, sync/export/import.
- **UI shell**: page-header system, section cards, modal patterns, form patterns, table/list patterns, chart accessibility patterns.
- **Platform**: web/PWA, Android/Capacitor, optional Electron desktop.

---

## 8. "Fully Completed" Definitions (per route)

### 8.1 Dashboard Cockpit
real data on all cards/charts; all actions real; empty/low-data states handled; metric explanations clear; monthly + current-period views coherent; drill-down paths.

### 8.2 Mission Control
household action center: warnings, due soon, savings at risk, unusual spending, missing data, reconciliation prompts, document-processing queue, AI actions, import tasks.

### 8.3 Ledger Loops
manual transactions; CSV import real; OFX/QFX/statement parsing; bank sync real or feature-flagged; reconciliation; editable categories; merchant normalization; dedupe.

### 8.4 Income Pool
recurring + one-time income; multiple people; source assignment; projections; status; notes; import hooks.

### 8.5 Pay Path
bills/debts editable; due calendars; autopay status; required-vs-optional; min + extra payment planning; payoff modeling; reminders; pressure analytics.

### 8.6 Stash Map
goal CRUD; progress; deadlines; required monthly contribution; underfunded/on-track labels; scenario planner; household priority; transfer recommendations.

### 8.7 Debt Center
amortization/payoff strategy; avalanche vs snowball; timeline; payment history; extra-payment strategy; health summaries.

### 8.8 Tax Taxi
tracker/records; form drafts marked draft unless truly generated; document links; person mapping; withholding/refund estimates; annual packet export.

### 8.9 The Vault
upload/download/delete; preview; categorize; tag; cross-link to entities; ingestion queue; OCR/extraction status; apply-extracted-data review; provenance.

### 8.10 Credit Snapshot
manual snapshots; trends; source/date/model/person attribution; reminders; do not imply automated fetch unless real.

### 8.11 Beacon Bridge
real export/import-based sync OR real peer/device sync; merge resolution; last-sync metadata; backup/restore.

### 8.12 Reports Arena
real JSON/CSV export; real print views; monthly household report; debt/savings/tax/document inventory reports.

### 8.13 Settings
theme; data export/import; clear data; feature flags; AI provider config; bank integration config; Android/web behavior; privacy controls.

---

## 9. Realistic Integration Strategy

### 9.1 Bank connectivity (tiered)
- **Tier A — guaranteed**: CSV import, statement import, QFX/OFX/CSV adapters, rule-based parsing, dedupe + review queue.
- **Tier B — aggregator**: optional Plaid/MX/Finicity layer with provider abstraction, explicit consent, no pretending unsupported institutions work.
- **Tier C — institution-specific**: only where actually supported; provider plugins; never hardcoded into core finance logic.

### 9.2 Document ingestion (phased)
1. local upload + tagging
2. OCR/parsing pipeline
3. extraction review UI
4. map extracted data to household entities
5. confidence scoring
6. human review before commit

### 9.3 AI assistant (real provider architecture)
- local provider (Ollama/OpenAI-compatible local endpoint)
- cloud provider option
- document-aware assistant
- budget-summary assistant
- action proposals
- no silent writes without confirmation

### 9.4 Device sync (sequenced)
1. export/import sync
2. signed merge bundles
3. optional local network pairing
4. WebRTC/socket sync only after data-conflict model is solved

---

## 10. Risk-Ordered Milestone Plan

### M0 — Repo Truth Reset
**Outputs**: rewritten `PRODUCT_BRIEF.md`, `PLAN.md`, `ROADMAP.md`, `WHERE_LEFT_OFF.md`; GUI completion map; integration strategy docs.
**Done**: docs no longer claim false completion; mocked surfaces explicitly listed; finish scope visible.

### M1 — GUI Surface Audit + Completion Matrix
**Outputs**: `docs/GUI_COMPLETION_MAP.md`; route-by-route completeness scoring; missing-actions inventory; dead-button inventory; mock-feature inventory; mobile-vs-web parity matrix.
**Done**: every visible control classified (real/partial/mock/missing/broken/polish-needed).

### M2 — Core Data + Validation Hardening
**Outputs**: schema review; typed service boundaries; safer import/export; more budget-engine tests; consistent validation.
**Done**: no major route writes inconsistent data; budget engine trustworthy.

### M3 — Full GUI Completion Pass
**Outputs**: completed forms; connected buttons; consistent cards/tables/lists; empty/error/loading states; responsive polish; Android-safe layouts; a11y improvements.
**Done**: no fake/dead controls; full CRUD on all major entities; all actions real or feature-flagged.

### M4 — Reports, Backup, Restore, Recovery
**Outputs**: real JSON/CSV export-import; restore flow; data wipe confirmation; report generators; versioned backup format.
**Done**: no casual data loss; reports/backup real; export buttons no longer fake.

### M5 — Ledger + Bank/Data Import Foundation
**Outputs**: CSV/statement import; mapping/review queue; dedupe; transaction normalization; import status UI.
**Done**: Ledger populatable from real external files; fake bank sync removed/flagged.

### M6 — Vault + OCR + Extraction Review
**Outputs**: OCR/extraction adapter architecture; extraction queue UI; review-before-commit flow; mapping to entities; provenance links.
**Done**: upload→parse→review→commit works for at least one supported document type; no mock extraction in production path.

### M7 — AI Assistant Real Integration
**Outputs**: provider abstraction; local provider first; optional cloud; telemetry-aware read-only analysis; later action proposals with confirmation.
**Done**: chatbot responses generated by configured provider; assistant actions bounded/logged/confirmation-gated.

### M8 — Tax/Credit/Debt/Household Planning Deepening
**Outputs**: debt strategy tools; tax packet/report improvements; honest credit-state clarity; cross-module planning; household summaries.
**Done**: advanced modules stop feeling like shells; terminology honest.

### M9 — Android/Web Final Polish + RC
**Outputs**: Android polish; PWA polish; desktop/web parity decisions; install/update/recovery docs; release checklist.
**Done**: app pleasant, coherent, safe for real household use; only intentionally deferred features remain.

---

## 11. Completion Threshold Matrix

- L0 — Shell (route exists, presentational)
- L1 — Basic CRUD
- L2 — Usable (states, validations, summaries, real actions)
- L3 — Polished (responsive, a11y, consistent, no dead controls)
- L4 — Production-Ready (integrated reports/imports/recovery + platform QA)

App is not "finished" until every major route reaches **L3**, and these reach **L4**: Dashboard, Ledger, Pay Path, Stash Map, Reports, Settings, Vault.

---

## 12. Highest-Risk Gaps

1. **Truthfulness gap** — docs claim done while runtime mocks remain.
2. **Mock integration gap** — bank sync, credit check, chatbot, bridge, document extraction simulated.
3. **Trust gap** — export/import/recovery/reporting must be fully real.
4. **Validation gap** — no top-level test command; need more route-level + import/export validation.
5. **Usability gap** — strong theming, but utility/info hierarchy must dominate over theater.

---

## 13. Claude Opus 4.6 Max Context Prompt Pack

### Prompt A — Repo Completion Audit
Load repo-local instructions first (AGENTS.md, _system/* contracts, PLAN.md, PRODUCT_BRIEF.md, ROADMAP.md, WHERE_LEFT_OFF.md, TODO.md, FIXME.md, TEST_STRATEGY.md, RISK_REGISTER.md). Perform repo-safe completion audit. Classify every feature (real/partial/mock/missing/broken/polish-needed). Produce: Current State, Completion Matrix, Mock Feature Inventory, GUI Gaps, Data/Validation Gaps, Integration Gaps, Mobile/Android Gaps, Release Risks. Rewrite PLAN/ROADMAP/WHERE_LEFT_OFF/TODO/FIXME/RISK_REGISTER. Do not implement. Be brutally honest. Respect repo-local precedence.

### Prompt B — GUI Completion Plan
Load repo-local instructions. Create route-by-route GUI completion plan covering all major routes + Android/web parity. For each route: current state, missing sub-features, dead/fake controls, data deps, UX gaps, a11y gaps, mobile gaps, completion checklist, validation checklist. Also: shared design-system checklist, component reuse map, IA cleanup plan, "style vs usability" correction plan. Keep Budget Beacon/Pay Path/Stash Map naming. Usability first.

### Prompt C — Real Integrations Strategy
Load repo-local instructions. Replace simulated capabilities with phased integration strategy across bank sync, document OCR, AI assistant, credit fetch, device sync, export/import, tax docs. For each: current reality, why not production-real, safest next phase, provider adapter architecture, security/privacy risks, UX for degraded states, feature-flag strategy, validation strategy. Don't assume direct bank API access; design fallback layers; secure credential storage; AI may not silently write financial data.

### Prompt D — Execute First Completion Milestone (M0)
Load repo-local instructions. Implement M0: repo truth reset + GUI completion matrix + doc alignment. Update PLAN.md, ROADMAP.md, WHERE_LEFT_OFF.md, TODO.md, FIXME.md, RISK_REGISTER.md. Create docs/GUI_COMPLETION_MAP.md and docs/INTEGRATIONS_STRATEGY.md if missing. No fake completion claims; no broad refactors; no feature implementation unless needed to correct contradictions. Output: Plan, Files changed, Summary, Validation, Next milestone, Remaining risks.

---

## 14. Quality Gates (definition of finished)

- every major route has a completion checklist and passes it
- no primary button is fake
- no mock integration remains exposed as if real
- reports/export/import are real
- core finance CRUD stable
- budget engine trusted and tested
- backup/restore works
- Android UI safe-area clean and route-complete
- web/PWA UI route-complete
- advanced features either real, hidden, or marked manual/coming-later
- repo docs match runtime reality

---

## 15. Review and Rollback Protocol

**Review (per milestone)**: review diffs; compare to GUI completion map; confirm no simulated feature is misrepresented; run validation; update handoff docs; commit only after milestone-level truth established.

**Rollback**: one milestone per commit; revert if needed; export data before destructive/import-heavy testing; feature-flag risky integration surfaces.

---

## 16. Final Recommendation

Don't try to "finish everything at once." Strongest sequence:

1. truth reset
2. GUI completion map
3. full GUI completion
4. recovery/export/report trust layer
5. real import/sync foundations
6. real OCR/AI/provider integrations
7. Android/web release polish

Budget Beacon already has strong bones, broad ambition, and a lot of visual work. What it needs now is disciplined conversion from impressive prototype to truthful finished product.
