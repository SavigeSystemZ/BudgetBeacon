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
- Executed Milestone **M4 — Reports / Backup / Restore / Recovery** (commit pending after this update):
  - **Backup format v3** — documents (Blob) now round-trip via base64. New `src/lib/encoding/base64.ts` with chunked encoder (handles >32 KB without RangeError) and a runtime fallback to `FileReader.readAsArrayBuffer` for older WebViews. v1 + v2 backups still validate on import.
  - **Real Reports Export** — `src/modules/reports/exportCsv.ts` produces RFC-4180 CSV per entity (transactions, bills, debts, savings goals, subscriptions, insurance, credit snapshots). Reports route now has an Export dropdown with all CSVs + a "Full backup (JSON v3)" shortcut. `featureFlags.reportsRealExport` flipped to `true`.
  - **Five report tabs** — Monthly (existing), Debts, Savings, Subscriptions, Documents. Each computes from real db data; debt report sorts Avalanche-order; savings report shows ETA per goal; subscriptions report sorts by monthly equivalent; document inventory groups by category.
  - **Restore-confirmation diff preview** — Settings now parses + validates the file first, then shows a `RestoreDiffPanel` with current-vs-backup row counts per table (additions in green, deletions in red). User confirms only after reviewing. New helpers `backupRowCounts()` and `currentDbRowCounts()` in `importJson.ts`.
  - **Print stylesheet** — `@media print` block in `src/index.css` forces white bg / black text, disables animations, sets `break-inside: avoid` on cards, hides nav and chatbot FAB.
  - **New tests** — base64 helpers (4 cases incl. >32 KB chunking boundary), CSV escape (4 cases), backup row-counts diff (1 case). Total 39 tests, all green.
  - **Audit-controls baseline updated** to `setTimeout=4 mathRandom=0 alert=0`. The 4 setTimeouts are all legit UX status-message timers (Settings savedFlash + importStatus reset, Reports CSV + JSON export confirmations).
- Executed Milestone **M3 (substantial pass) — Full GUI Completion** in two commits:
  - **M3.1 (commit `72c86c3`)** — removed highest-harm fake controls in Vault, Ledger, Credit, Beacon Bridge. Introduced shared `featureFlags` map (`src/lib/flags/featureFlags.ts`) and `DemoBadge` component (`src/components/ui/DemoBadge.tsx`).
  - **M3.2 (commit `ae1bbb5`)** — every remaining `alert()` removed from `src/`. New `stabilityIndex` module + tests; Mission Control / Reports now use the real index. Mission Control's Largest Liability + Stash Velocity cards now compute from real db. Insurance Inspect rewritten as honest manual CRUD against `insuranceRecords`. Settings rewritten with real `localStorage`-backed preferences and Dexie-backed AI Config persistence. Chatbot now clearly labeled Demo until M7.
  - **Audit-controls counts:** `setTimeout` 10 → 2 (both remaining are legit Settings UX timers), `mathRandom` 2 → 0, `alert` 15 → 0.
  - **Validation:** `npm test` 29 passed; `npm run typecheck` clean.
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

**Next milestone: M5 — Ledger + Bank/Data Import Foundation.** M4 finished the trust layer (real CSV/JSON exports, real restore preview, v3 backup with documents). The Ledger now needs honest *inputs*: replace the M3 "import coming in M5" placeholder card with real CSV / QFX / OFX file import.

**M5 concrete work (in suggested order):**

1. **CSV import for transactions** — file picker → header mapping (let the user choose which CSV column is date / payee / amount / category) → preview as a review queue → dedupe by (date + amount + payee) → bulk commit on confirm. Flip `featureFlags.bankImportTierA` to `true` once the happy path lands.
2. **QFX / OFX scaffolded parser** — minimal SGML/XML reader; plenty of bank exports use it. Either ship a small in-house parser or document a clean adapter interface that a future dependency can satisfy.
3. **Merchant / payee normalization** — configurable regex rules (e.g., `^AMZN MKTP US.*$ → Amazon`). Persist rules to a new `payeeRules` Dexie table.
4. **Review queue UI in Ledger** — replace the current "Bank Import (M5)" `DemoBadge` card with the actual queue: list of incoming transactions with edit-before-commit and per-row reject.
5. **Tax forms cleanup (M3 carry-over)** — the Tax Taxi form is still 2 placeholder fields. M5 or M8 should either build proper per-form-type fields or label them "manual notes."
6. **`audit:controls` baseline** locked at `setTimeout=4 mathRandom=0 alert=0`. New M5 work must not raise these without intentional baseline update.

**Reference for M5 design:** `docs/INTEGRATIONS_STRATEGY.md` Domain 1 (Bank connectivity) Phase 1 — Tier A only. Tier B (Plaid/MX aggregator) explicitly deferred until Tier A is proven insufficient.

**Validation surface available now:**
- `npm test` — 22 tests across budget engine, stash-map, backup round-trip
- `npm run typecheck` — full TS compile, no emit
- `npm run lint` — eslint
- `npm run audit:controls` — mock-regression check
- `npm run build` — production Vite build (Capacitor sync runs separately)

## Build / sync state
- `npm test` — 39 passed (verified at M4 close, 2026-04-26)
- `npm run typecheck` — clean (verified at M4 close)
- `npm run audit:controls` — baseline locked at `setTimeout=4 mathRandom=0 alert=0 emptyOnClick=0`; all 4 setTimeouts are legit UX status-message timers
- `npm run build` — re-verify before next milestone
- `npx cap sync` — re-verify before Android smoke
- Database: Dexie v4 active; **backup format v3** (covers all 18 tables including `documents` Blob via base64; v1/v2 still accepted on import)

## Hard rules for the next agent
1. **Do not re-introduce "Mission Ready" / "fully delivered" language anywhere.** If you find it, fix it.
2. **Do not delete mocked surfaces silently.** Either replace with real implementation, hide behind a feature flag, or label honestly. Document the choice.
3. **Backup before destructive testing.** Use Settings → Export before any `clearDatabase` work.
4. **Prefer commits per milestone, not per file.** M0 should land as one commit.
