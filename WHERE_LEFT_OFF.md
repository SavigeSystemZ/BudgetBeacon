# Where Left Off — 2026-04-25

> **Truth Reset.** Previous version claimed "Mission Ready. Secured. Polished." That claim was inaccurate; multiple primary action buttons across the app are mocked or alert-only. This file is now an honest handoff. See `docs/COMPLETION_MASTER_PLAN.md` for the full plan, `docs/GUI_COMPLETION_MAP.md` for per-route evidence, and `docs/GUI_COMPLETION_CHECKLIST.md` for per-control fix assignments.

## What just happened
- Performed full repo audit across `src/routes/` (15 routes), `src/components/BeaconChatbot.tsx`, `src/db/db.ts`, `src/App.tsx`, and `package.json`.
- Executed Milestone **M0 — Repo Truth Reset** (doc-only, no code changes):
  - Rewrote `PLAN.md`, `ROADMAP.md`, `TODO.md`, `FIXME.md`, `RISK_REGISTER.md`, this file.
  - Created `docs/GUI_COMPLETION_MAP.md` and `docs/INTEGRATIONS_STRATEGY.md`.
  - Saved `docs/COMPLETION_MASTER_PLAN.md` (master narrative).
- Executed Milestone **M1 — GUI Surface Audit & Completion Matrix** (doc-only):
  - Created `docs/GUI_COMPLETION_CHECKLIST.md` with per-control inventory across all 15 routes + chatbot.
  - ~140 buttons + ~80 form fields enumerated; status distribution: ~95 REAL, ~20 MOCKED-SETTIMEOUT, ~10 ALERT-ONLY, ~15 NO-OP.
  - Component-reuse map, empty/loading/error state matrix, mobile/Android parity matrix all in checklist.
  - Highest-priority M3 must-fix list ordered by user-visible harm (Vault Commit-to-App is #1 — it writes mock data to real db on one click).
- Executed Milestone **M2 — Core Data + Validation Hardening** (first code-touching milestone):
  - **Test infrastructure**: added `npm test`, `npm run test:watch`, `npm run typecheck`, `npm run audit:controls` scripts. Created `vitest.config.ts` (jsdom env) and `vitest.setup.ts` (loads `fake-indexeddb/auto` + jest-dom matchers).
  - **Discovered M0/M1 audit inaccuracies (now corrected below)**: there were already 2 test files (`budget-engine.test.ts` 12 cases, `stash-map.calculations.test.ts` 5 cases) — total 17 pre-existing tests. The biweekly factor in the *budget engine itself* (`frequency.ts`) was already correct (`52/12 ≈ 2.1667`); the bug was in `IncomeRoute.tsx` lines 36–46 which had a *duplicate* incorrect display calculation.
  - **Fixed IncomeRoute drift**: replaced the duplicate calc with a call to the shared `toMonthlyEquivalent` from the budget engine. Now also handles `semimonthly` and `custom` frequencies (the duplicate ignored both).
  - **CRITICAL fix — backup completeness**: the original `exportDatabaseToJson` only exported 8 of 18 db tables. Restoring a backup silently wiped the user's `subscriptions`, `taxRecords`, `taxTransactions`, `taxForms`, `aiConfig`, `chatMessages`, `insuranceRecords`, `syncLogs`, and `debtTransactions`. Bumped backup format to v2; added all non-blob tables; v1 backups still validate (backward-compat). `documents` (Blob) is intentionally excluded — base64 round-trip deferred to M4.
  - **New test**: `src/modules/reports/backup.test.ts` (5 cases) — version field present, all v2 tables exported, full round-trip equality, v1 legacy acceptance, malformed-rejection.
  - **Error boundary**: added `src/components/ErrorBoundary.tsx`. Wired root + per-route in `src/App.tsx` so a render error in one route can't blank the whole app. Each route's boundary names the route on the fallback UI.
  - **Audit-controls tool**: `tools/audit-controls.ts` greps `src/routes` + `src/components` for `setTimeout`, `Math.random`, `alert(`, empty `onClick={() => {}}` and fails if counts increase vs `tools/audit-controls.baseline.json`. Baseline recorded 2026-04-25: **setTimeout=10, Math.random=2, alert=15, emptyOnClick=0**. M3 should drive these down.
  - **Validation**: `npm test` → 22 passed (3 files). `npm run typecheck` → clean.

## Honest state of the app

### What is real
- **Routes:** All 15 routes wired in `src/App.tsx:173-189` (HashRouter).
- **Persistence:** Dexie v4 schema with 18 tables (`src/db/db.ts`). Real CRUD on Income, Pay Path (bills + debts), Stash Map (goals), Subscriptions, Tax Taxi (records), Ledger (manual transactions), Document Store (Blob storage), Credit (manual snapshots), Debt Center (debts + debt transactions).
- **Settings:** Real JSON export/import/wipe (`SettingsRoute.tsx:26-61`), via `exportDatabaseToJson` / `importDatabaseFromJson` / `clearDatabase`.
- **Aggregations:** `calculateBudgetSummary()` is a real (basic) aggregation used by Dashboard, Mission Control, Reports.
- **Build:** `npm run build` is clean per prior handoff. Capacitor sync OK.

### What is mocked or simulated (high-confidence findings from audit)
| Surface | File:Line | What's fake |
|---|---|---|
| Beacon chatbot | `src/components/BeaconChatbot.tsx:44-62` | `setTimeout` + canned if/else; no LLM call |
| Ledger Bank Sync | `src/routes/LedgerRoute.tsx:53-62` | `setTimeout` + 2 hardcoded transactions (Starbucks, Amazon) |
| Ledger Scavenge | `src/routes/LedgerRoute.tsx:65-78` | `setTimeout` + 2 hardcoded items |
| Document Store Scavenge | `src/routes/DocumentStoreRoute.tsx:74-84` | `setTimeout` + hardcoded extraction (income $1450, bill $174.70) |
| Credit Bank Fetch | `src/routes/CreditRoute.tsx:57-63` | `setTimeout` + `Math.random()` score |
| Credit "Free Credit Check" | `src/routes/CreditRoute.tsx:68-74` | `setTimeout` + `Math.random()` score |
| Beacon Bridge target | `src/routes/BeaconBridgeRoute.tsx:21` | Hardcoded "Partner's Phone (iPhone 15)" |
| Beacon Bridge sync | `src/routes/BeaconBridgeRoute.tsx:28-37` | Simulated merge; writes one fake `syncLogs` row + alert |
| Insurance Inspect | `src/routes/InsuranceInspectRoute.tsx:16-26, 55-67` | Hardcoded quotes (Progressive/Geico/State Farm) and active policies |
| Mission Control "Persist Plan" | `src/routes/BudgetMissionControlRoute.tsx:32` | `alert("Strategic plan saved.")` only |
| Mission Control Stability Index | `src/routes/BudgetMissionControlRoute.tsx:102-103` | Hardcoded 85 / 45, not calculated |
| Mission Control forecast text | `src/routes/BudgetMissionControlRoute.tsx:169` | Hardcoded "65% complete... by August 2026" |
| Dashboard "Save Cockpit" | `src/routes/DashboardRoute.tsx:76` | `alert("Snapshot saved.")` only |
| Reports Export | `src/routes/ReportsRoute.tsx:35` | `alert("Report Exported.")` only |
| Settings "Save All" | `src/routes/SettingsRoute.tsx:64-66` | Alerts only; UI toggles do not persist |
| Settings AI Config | `src/routes/SettingsRoute.tsx:241-266` | Form accepts input but does not persist or validate endpoint |
| Tax Taxi form | `src/routes/TaxTaxiRoute.tsx:233-234` | Two placeholder fields ("Entity / Payer", "Gross Telemetry"); not a real form |

### Infrastructure gaps (status as of M2 close)
- ~~No `test` script in `package.json`.~~ **Resolved M2.** `npm test` runs Vitest (22 tests, 3 files).
- ~~No `typecheck` script.~~ **Resolved M2.** `npm run typecheck` available.
- ~~No error boundaries anywhere in the React tree.~~ **Resolved M2.** Root + per-route boundaries via `ErrorBoundary`.
- **Still gap:** no retry logic, no offline graceful-degradation. (Will become relevant when M5/M7 add network calls.)
- **New tooling:** `npm run audit:controls` flags any increase in mocked-control counts.

## Where to pick up next

**Next milestone: M3 — Full GUI Completion Pass.** Punch list is in `docs/GUI_COMPLETION_CHECKLIST.md` "Highest-priority controls (M3 must-fix list)" — 10 ordered items. Top priorities by user-visible harm:

1. **Vault `6.7` "Commit to App"** — disable; it writes mock-extracted data to real db on a single click. (Highest harm in the app.)
2. **Ledger `9.1`/`9.2`/`9.6`** — Bank Sync, Scavenge, Commit-All all write fabricated transactions. HIDE/LABEL.
3. **Credit `3.1`/`3.2`** — Bank Fetch + Credit Check write `Math.random` scores. REMOVE.
4. **Beacon Bridge `1.1`/`1.2`** — fake sync. HIDE/LABEL.
5. **Insurance Inspect (whole route)** — entirely L0 hardcoded. LABEL as "Demo" or hide.
6. **Settings toggles + AI Config** — 7 toggles + Model input have no `onChange`/`onClick`. WIRE all or REMOVE.
7. **Mission Control 2.1/2.2/2.3** — alert + hardcoded stability/forecast. CALCULATE from real data.
8. **Dashboard 4.2/4.5** — alert "Save Cockpit" + no-op "Execute Deep Audit". REMOVE.
9. **Reports 11.1** — Export alert. LABEL "M4 — coming soon."
10. **Chatbot C.4** — canned replies. LABEL "Demo".

After each M3 commit, run `npm run audit:controls` — counts should monotonically decrease (current baseline: setTimeout=10, Math.random=2, alert=15). When intentionally removing mocks, run `npm run audit:controls -- --update` to record the new lower baseline.

**Validation surface available now:**
- `npm test` — 22 tests across budget engine, stash-map, backup round-trip
- `npm run typecheck` — full TS compile, no emit
- `npm run lint` — eslint
- `npm run audit:controls` — mock-regression check
- `npm run build` — production Vite build (Capacitor sync runs separately)

## Build / sync state
- `npm test` — 22 passed (verified at M2 close, 2026-04-25)
- `npm run typecheck` — clean (verified at M2 close)
- `npm run audit:controls` — baseline recorded; no regressions
- `npm run build` — clean per prior handoff (re-verify before M3 sweep)
- `npx cap sync` — clean per prior handoff
- Database: Dexie v4 active

## Hard rules for the next agent
1. **Do not re-introduce "Mission Ready" / "fully delivered" language anywhere.** If you find it, fix it.
2. **Do not delete mocked surfaces silently.** Either replace with real implementation, hide behind a feature flag, or label honestly. Document the choice.
3. **Backup before destructive testing.** Use Settings → Export before any `clearDatabase` work.
4. **Prefer commits per milestone, not per file.** M0 should land as one commit.
