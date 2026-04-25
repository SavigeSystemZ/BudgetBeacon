# GUI Completion Map

Generated: 2026-04-25 (M0 truth reset). Source of truth for route-by-route completion state. Cross-referenced from `PLAN.md`, `ROADMAP.md`, `TODO.md`, `FIXME.md`, `RISK_REGISTER.md`.

## Completion threshold legend

(Per `docs/COMPLETION_MASTER_PLAN.md` §11.)

- **L0 — Shell.** Route exists; mostly presentational.
- **L1 — Basic CRUD.** User can add/view/edit/delete core records.
- **L2 — Usable.** States, validations, summaries, and route actions are real.
- **L3 — Polished.** Responsive, accessible, visually consistent, no dead controls.
- **L4 — Production-Ready.** Integrated with reports, imports, recovery, and platform QA.

**Done definition for "Budget Beacon finished":** every major route ≥ L3, and Dashboard / Ledger / Pay Path / Stash Map / Reports / Settings / Vault ≥ L4.

## Per-route completion table

| # | Route | File | Current Level | Target | Gap |
|---|---|---|---|---|---|
| 1 | Dashboard Cockpit | `src/routes/DashboardRoute.tsx` | L2 | L4 | "Save Cockpit" alert; needs polish + report integration |
| 2 | Mission Control | `src/routes/BudgetMissionControlRoute.tsx` | L1 | L3 | Hardcoded Stability Index + forecast text; alert-only Persist Plan |
| 3 | Ledger Loops | `src/routes/LedgerRoute.tsx` | L1 (real) + L0 (sync/scavenge fake) | L4 | Mocked Bank Sync + Scavenge; needs real CSV import + review queue |
| 4 | Income Pool | `src/routes/IncomeRoute.tsx` | L2 | L3 | Biweekly factor approximation; otherwise solid |
| 5 | Pay Path | `src/routes/PayPathRoute.tsx` | L2 | L4 | Solid CRUD; needs payment-pressure analytics |
| 6 | Stash Map | `src/routes/StashMapRoute.tsx` | L2 | L4 | Solid CRUD; needs forecasting + scenario planner |
| 7 | Debt Center | `src/routes/DebtCenterRoute.tsx` | L2 | L3 | Solid CRUD; needs avalanche/snowball comparison |
| 8 | Tax Taxi | `src/routes/TaxTaxiRoute.tsx` | L1 | L3 | Form is 2-field placeholder; needs real fields or honest "manual" label |
| 9 | The Vault (Documents) | `src/routes/DocumentStoreRoute.tsx` | L1 (storage real) + L0 (scavenge fake) | L4 | Mocked OCR; needs real Tesseract pipeline + review |
| 10 | Subscriptions Shelf | `src/routes/SubscriptionsShelfRoute.tsx` | L2 | L3 | Solid CRUD; cancellation templates are strings (acceptable) |
| 11 | Insurance Inspect | `src/routes/InsuranceInspectRoute.tsx` | L0 | L2 (or hide) | All hardcoded; replace with manual policy CRUD |
| 12 | Beacon Bridge | `src/routes/BeaconBridgeRoute.tsx` | L0 | L2 | Mocked sync; replace with signed export/import |
| 13 | Credit Snapshot | `src/routes/CreditRoute.tsx` | L1 (manual real) + L0 (fetch fake) | L3 | Random-score fetch buttons; remove |
| 14 | Reports Arena | `src/routes/ReportsRoute.tsx` | L1 | L4 | Export is alert-only; print works |
| 15 | Settings | `src/routes/SettingsRoute.tsx` | L1 (export/import real) + L0 (toggles fake) | L4 | Toggles + AI Config don't persist |

---

## Per-route detail

### 1. Dashboard Cockpit (`src/routes/DashboardRoute.tsx`) — L2 → L4
**Real:** reads all major tables (lines 21–27); calls `calculateBudgetSummary` (line 31); `handleClearAll` is real wipe (lines 50–64).
**Mocked / dead:** `alert("Snapshot saved.")` at line 76.
**Missing:** drill-down paths from cards into route-specific filtered views; metric explanations; low-data state copy beyond guard at line 66.
**Path to L4:** M3 removes/replaces "Save Cockpit." M4 wires "Export this view" to real export. Add metric tooltips.

### 2. Mission Control (`src/routes/BudgetMissionControlRoute.tsx`) — L1 → L3
**Real:** reads incomes, bills, debts, savings goals, transactions, subscriptions, insurance (lines 12–18); calls budget summary (line 24).
**Mocked / dead:**
- `alert("Strategic plan saved.")` at line 32.
- Stability Index hardcoded `85` / `45` at lines 102–103.
- Forecast text hardcoded "65% complete... by August 2026" at line 169.
**Missing:** real action center (warnings, due-soon, savings-at-risk, reconciliation prompts).
**Path to L3:** M3 calculates Stability Index from real summary; computes savings velocity for forecast; replaces Persist Plan with real plan persistence (new table) or removes.

### 3. Ledger Loops (`src/routes/LedgerRoute.tsx`) — split state → L4
**Real (L2):** transaction CRUD (lines 25–47, 152); reads documents and households.
**Mocked / dead (L0):**
- "Bank Sync" button: `setTimeout(2500)` + 2 hardcoded txns (lines 53–62).
- "Scavenge Statements" button: `setTimeout(3000)` + 2 hardcoded items (lines 65–78).
**Missing:** CSV import; OFX/QFX parsing; reconciliation; merchant normalization; deduplication.
**Path to L4:** M3 disables mock buttons. M5 ships real CSV import → mapping → dedupe → review-queue → commit. M5 also scaffolds OFX/QFX.

### 4. Income Pool (`src/routes/IncomeRoute.tsx`) — L2 → L3
**Real:** CRUD on `incomeSources` (lines 22–55, 107); frequency normalization (lines 36–46).
**Mocked / dead:** none.
**Bug:** biweekly factor `2.16` should be `26/12 ≈ 2.1667` (lines 36–46).
**Missing:** projections; multi-source per person summaries; status (active/paused).
**Path to L3:** M2 fixes factor + adds test. M3 polishes per-person grouping.

### 5. Pay Path (`src/routes/PayPathRoute.tsx`) — L2 → L4
**Real:** full CRUD on bills + debts (lines 21–60, 115, 144).
**Mocked / dead:** none.
**Missing:** due calendar; autopay status surfacing; required-vs-optional classification; min + extra payment planning UI; payment pressure analytics.
**Path to L4:** M3 adds due-soon view + autopay flag UI. M8 adds extra-payment planner.

### 6. Stash Map (`src/routes/StashMapRoute.tsx`) — L2 → L4
**Real:** goal CRUD (lines 23–96); progress is `(current/target) * 100`.
**Mocked / dead:** none.
**Missing:** required monthly contribution calc; underfunded/on-track labels; scenario planner; transfer-from-surplus suggestions.
**Path to L4:** M3 adds contribution calc + on-track label. M8 adds scenario planner.

### 7. Debt Center (`src/routes/DebtCenterRoute.tsx`) — L2 → L3
**Real:** debt CRUD + debt transactions (lines 37–61); chart deterministic from history (lines 81–93).
**Mocked / dead:** none.
**Missing:** amortization; avalanche-vs-snowball comparison; payoff timeline; extra-payment strategy.
**Path to L3:** M8 adds strategy comparison and timeline.

### 8. Tax Taxi (`src/routes/TaxTaxiRoute.tsx`) — L1 → L3
**Real:** tax record CRUD + tax forms persistence (lines 23–80, 167).
**Mocked / dead:** form has only "Entity / Payer" and "Gross Telemetry" placeholder fields (lines 233–234).
**Missing:** real form fields (filer, income type, withholding, year); document linkage; annual packet export.
**Path to L3:** M8 builds real fields OR re-labels as "manual draft assist"; either way, drop the "telemetry" wording.

### 9. The Vault (`src/routes/DocumentStoreRoute.tsx`) — split state → L4
**Real (L1):** upload/store/delete via Blob (lines 18–55, 102).
**Mocked / dead (L0):**
- "Scavenge" returns hardcoded extraction (lines 74–84).
- `applyScavengedData` writes those fake records to db (lines 87–99) **without review**.
**Missing:** preview; tagging UI; cross-link to entities; ingestion queue; OCR pipeline; provenance.
**Path to L4:** M3 disables Scavenge. M6 ships real Tesseract OCR + per-field confidence + review-before-commit + provenance link.

### 10. Subscriptions Shelf (`src/routes/SubscriptionsShelfRoute.tsx`) — L2 → L3
**Real:** subscription CRUD (lines 46–96); template generator (lines 99–105).
**Mocked / dead:** templates are hardcoded strings — acceptable; not pretending to be AI. Email "send" is `mailto:` (acceptable).
**Missing:** renewal calendar; price-change tracking.
**Path to L3:** M3 adds renewal-soon view.

### 11. Insurance Inspect (`src/routes/InsuranceInspectRoute.tsx`) — L0 → L2 (or hide)
**Real:** none — route uses local state only, no db writes.
**Mocked / dead:**
- "Execute Inspection" returns hardcoded Progressive/Geico/State Farm quotes (lines 16–26).
- Active Shield section hardcoded (lines 55–67).
**Missing:** all real CRUD.
**Path to L2:** M9 replaces with manual policy CRUD against existing `insuranceRecords` table; or hide route behind disabled flag until rebuilt.

### 12. Beacon Bridge (`src/routes/BeaconBridgeRoute.tsx`) — L0 → L2
**Real:** writes one row to `syncLogs` table (line 30) — but it's a fake row.
**Mocked / dead:**
- Hardcoded "Partner's Phone (iPhone 15)" device (line 21).
- Simulated merge via `setTimeout(3500)` + alert (lines 28–37).
**Missing:** any real sync logic.
**Path to L2:** M9 replaces with signed JSON export/import bundle path. P2P/WebRTC explicitly deferred.

### 13. Credit Snapshot (`src/routes/CreditRoute.tsx`) — split state → L3
**Real (L1):** manual snapshot CRUD (lines 26–50, 146).
**Mocked / dead (L0):**
- "Bank Fetch" → `setTimeout(2500)` + `Math.random()` score (lines 57–63).
- "Free Credit Check" → `setTimeout(4000)` + `Math.random()` score (lines 68–74).
**Missing:** trends visualization beyond what's there; reminder cadence.
**Path to L3:** M8 removes both fake buttons. Manual entry stays — that's the honest baseline.

### 14. Reports Arena (`src/routes/ReportsRoute.tsx`) — L1 → L4
**Real:** reads all tables (lines 10–16); aggregations real; `window.print()` works (line 25).
**Mocked / dead:** "Export" → `alert("Report Exported.")` at line 35.
**Missing:** real CSV/JSON export; PDF; per-report views (monthly, debt, savings, tax).
**Path to L4:** M4 ships real CSV + JSON export (versioned schema) + per-report views. PDF via print-to-PDF or jsPDF.

### 15. Settings (`src/routes/SettingsRoute.tsx`) — split state → L4
**Real (L1):** JSON export/import/wipe (lines 26–61); demo seed (line 324).
**Mocked / dead (L0):**
- `handleSaveAll` alerts only (lines 64–66).
- Toggles (theme/notifications/security/automation) don't persist (lines 168–209).
- AI Config form doesn't persist (lines 241–266).
**Missing:** preferences table or localStorage layer; AI provider validation.
**Path to L4:** M3 wires toggles to a `preferences` mechanism; wires AI Config to existing `aiConfig` table. M7 adds AI provider connection test.

---

## Cross-cutting GUI gaps

### Component-reuse coverage
Existing premium components: `GlassCard`, `PageHeader`, `EmptyState`, `BeaconModal`, `AgenticTooltip`, `BeaconChatbot`. M1 must enumerate each route's adoption gaps (e.g., do all routes use `PageHeader`? Are all empty states `EmptyState`?). Defer until M1.

### Loading / empty / error states
- **Loading:** Routes use `useLiveQuery` with conditional render. No skeletons; no progressive loading. Acceptable for L3.
- **Empty:** `EmptyState` component used in 8 routes. M1 confirms remaining 7.
- **Error:** No error boundaries anywhere. Form errors render inline; no toast/banner system. M2 adds boundaries; M3 adds toast for write errors.

### Mobile / Android
- HashRouter used (`src/App.tsx:171`) — Android-friendly.
- Bottom-nav + safe areas implemented per prior handoff; M9 re-verifies on real device.
- Hit-target sizing audit deferred to M1.

### Accessibility
- Not yet audited. Defer first pass to M3 (color contrast, focus order, aria-labels on icon buttons).

### Information architecture / theatrical wording
Several routes use sci-fi flavor wording that competes with utility ("Telemetry," "Scavenge," "Mission Control," "Beacon Bridge," "Stability Index"). Decision deferred — keep flavor for now since branding is intentional, but ensure functional labels are clear (e.g., "Persist Plan" should become "Save plan" or be removed).

## What this map enables

- **M1** uses this to deepen into per-control checklists.
- **M3** uses this to prioritize which dead controls to fix first (Bank Sync + Scavenge are highest-risk because they write fabricated data to real db).
- **Release readiness check (M9):** every row reaches its Target column.
