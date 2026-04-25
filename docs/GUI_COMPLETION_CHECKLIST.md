# GUI Completion Checklist (M1 deliverable)

Generated: 2026-04-25 (M1). Per-control checklist deepening `docs/GUI_COMPLETION_MAP.md`. Every interactive control across all 15 routes plus `BeaconChatbot` is enumerated with current status, target action, and the milestone that owns the fix.

**Inventory totals:** ~140+ buttons, ~80+ form fields, 10 BeaconModal instances, 7 Recharts visualizations, 1 tab system. Status distribution: ~95 REAL, ~20 MOCKED-SETTIMEOUT, ~10 ALERT-ONLY, ~15 NO-OP (handler missing).

**Status legend:**
- ✅ **REAL** — does real work against db / state
- ⚠️ **ALERT-ONLY** — fires `alert()` and persists nothing
- 🚨 **MOCKED-SETTIMEOUT** — simulates async with `setTimeout` and returns hardcoded or `Math.random` data
- ❌ **NO-OP** — JSX rendered but no `onClick` handler attached
- 🔌 **DEAD** — handler exists but writes to nothing useful

**Action keys for the "Fix" column:**
- `M2`–`M9` — milestone that owns the fix (per `ROADMAP.md`)
- `REMOVE` — delete the control; no replacement planned
- `HIDE` — feature-flag off until the milestone lands
- `LABEL` — add "Demo" / "Coming soon" / "Manual draft" wording until real

---

## Route 1 — Beacon Bridge (`src/routes/BeaconBridgeRoute.tsx`)

| # | Control | Type | Line | Status | Target | Fix |
|---|---|---|---|---|---|---|
| 1.1 | "Scan for Nearby Beacons" | button | 71 | 🚨 setTimeout fake device | Real local-network discovery (deferred) | M9 — replace with signed-bundle export/import; HIDE/LABEL until then |
| 1.2 | "Merge Data" | button | 95 | 🚨 setTimeout + fake `syncLogs` row + alert | Real bundle merge with diff preview | M9 — replace; HIDE/LABEL meanwhile |
| 1.3 | "Dismiss Terminal" | button | 126 | ✅ REAL state reset | n/a | keep |
| 1.4 | "Authorize New Instance" | button (ghost) | 152 | ❌ NO-OP no handler | Either wire to bundle-pairing flow or remove | M3 — remove; M9 — re-add with real action |

**Route-level notes:**
- Whole route is L0; until M9 it should be wrapped in a "Demo" banner.
- `syncLogs` table is real; M9 will use it for honest sync history once bundles work.

---

## Route 2 — Mission Control (`src/routes/BudgetMissionControlRoute.tsx`)

| # | Control | Type | Line | Status | Target | Fix |
|---|---|---|---|---|---|---|
| 2.1 | "Persist Plan" | button | 32 | ⚠️ alert-only | Save plan record (new `plans` table) or remove | M3 — REMOVE for now; M8 — add real plan persistence |
| 2.2 | Stability Index circular SVG | display | 85–103 | 🚨 hardcoded `85` / `45` based on a single boolean | Real index from `calculateBudgetSummary` (margin %, savings rate, debt-to-income, on-track-goals %) | M3 — calculate from summary |
| 2.3 | "Forecast" text block | display | 169 | 🚨 string literal "65% complete... by August 2026" | Calculated savings velocity per goal | M3 — compute from goals + monthly contribution |
| 2.4 | Progress bars (3) | display | 52, 59, 69 | ✅ REAL read-only | n/a | keep |

**Route-level notes:**
- Mission Control should become the household action center per `docs/COMPLETION_MASTER_PLAN.md` §8.2 — add: due-soon list, savings-at-risk, reconciliation prompts. M3 scope.

---

## Route 3 — Credit Snapshot (`src/routes/CreditRoute.tsx`)

| # | Control | Type | Line | Status | Target | Fix |
|---|---|---|---|---|---|---|
| 3.1 | "Bank Fetch" | button | 96 | 🚨 setTimeout + `Math.random` score | Realistically unavailable | M3 — REMOVE |
| 3.2 | "Credit Check" | button | 100 | 🚨 setTimeout + `Math.random` score | Realistically unavailable | M3 — REMOVE |
| 3.3 | "+" Add Snapshot | button | 104 | ✅ opens modal | n/a | keep |
| 3.4 | Person filter (NativeSelect) | form-field | 119 | ✅ REAL filter | n/a | keep |
| 3.5 | Snapshot delete (icon) | button | 146 | ✅ `db.creditSnapshots.delete` | n/a | keep |
| 3.6 | "Log Credit Score" submit | button | 195 | ✅ writes `creditSnapshots` | n/a | keep |
| 3.F1 | Snapshot form: Person, Score, Date, Bureau/Model | form | 172–196 | ✅ REAL → `creditSnapshots` | Add notes field; add reminder cadence | M8 |
| 3.C1 | Score Trajectory LineChart | chart | 127–135 | ✅ REAL, real data | Add per-person color legend | M3 polish |

---

## Route 4 — Dashboard Cockpit (`src/routes/DashboardRoute.tsx`)

| # | Control | Type | Line | Status | Target | Fix |
|---|---|---|---|---|---|---|
| 4.1 | "Wipe All" | button (destructive) | 75 | ✅ REAL, confirmed wipe of 8 tables | Add backup-first prompt | M4 |
| 4.2 | "Save Cockpit" | button | 76 | ⚠️ alert-only | Snapshot of cockpit metrics to `dashboardSnapshots` (new table) or remove | M3 — REMOVE for now |
| 4.3 | Budget Status Indicator + AgenticTooltip | display | 82 | ✅ REAL derived | n/a | keep |
| 4.4 | "Secured Offline Engine" badge | display | 102 | ❌ no handler — but no handler intended | n/a | keep as static |
| 4.5 | "Execute Deep Audit" | button | 211 | ❌ NO-OP no handler | Run validation pass (orphan refs, schema integrity, balance reconciliation) | M3 — REMOVE; M4 — re-add with real audit |
| 4.C1 | AllocationDonut | chart | 123 | ✅ REAL | n/a | keep |
| 4.C2 | Outflow Velocity AreaChart | chart | 135–149 | ✅ REAL 30-day spend | Add hover tooltip with date | M3 polish |
| 4.C3 | Pressure Index bar | display | 161–183 | ✅ REAL CSS gradient | Verify formula; add legend | M3 |

---

## Route 5 — Debt Center (`src/routes/DebtCenterRoute.tsx`)

| # | Control | Type | Line | Status | Target | Fix |
|---|---|---|---|---|---|---|
| 5.1 | "Add Liability" | button | 103 | ✅ opens modal | n/a | keep |
| 5.2 | Edit Debt (icon) | button | 148 | ✅ REAL | n/a | keep |
| 5.3 | Delete Debt (icon) | button | 149 | ✅ REAL | Add confirm | M3 |
| 5.4 | "Register Collection" submit | button | 200 | ✅ writes `debts` + `debtTransactions` | n/a | keep |
| 5.F1 | Debt form: Label, Balance, Min Payment | form | 184–202 | ✅ REAL | Add: interest rate, due day, status, owner — already in schema (lines 24–31) | M3 |
| 5.C1 | Liability Trajectory LineChart | chart | 119–128 | ✅ REAL 6-month history | n/a | keep |

**Route-level notes:**
- M8 adds avalanche vs snowball comparison + payoff timeline. Schema already supports it.

---

## Route 6 — The Vault (`src/routes/DocumentStoreRoute.tsx`)

| # | Control | Type | Line | Status | Target | Fix |
|---|---|---|---|---|---|---|
| 6.1 | "+" Upload | button | 113 | ✅ opens modal | n/a | keep |
| 6.2 | File input | form-field (file) | 231 | ✅ REAL Blob storage | n/a | keep |
| 6.3 | Cancel modal | button | 233 | ✅ REAL | n/a | keep |
| 6.4 | View Document | button | 197 | ✅ opens blob in new window | n/a | keep |
| 6.5 | Scavenge Document | button | 200 | 🚨 setTimeout + hardcoded extraction | Real OCR (Tesseract) + review queue | M3 — HIDE/LABEL; M6 — replace |
| 6.6 | Delete Document (icon) | button | 189 | ✅ REAL | Add confirm | M3 |
| 6.7 | "Commit to App" | button | 150 | 🔌 writes mock-extracted records to db **without review** | Per-field review-before-commit | **M3 critical — DISABLE until M6 ships review UI** |
| 6.F1 | Upload form: Label, Classification, File | form | 212–234 | ✅ REAL → `documents` | Add tags, person link | M3 |

**Route-level notes:**
- 6.7 is the highest-risk control in the app — it commits fabricated extraction to real db on a single click. Must be disabled in M3 even though M6 owns the real fix.

---

## Route 7 — Income Pool (`src/routes/IncomeRoute.tsx`)

| # | Control | Type | Line | Status | Target | Fix |
|---|---|---|---|---|---|---|
| 7.1 | "+" Add Income | button | 80 | ✅ opens modal | n/a | keep |
| 7.2 | Edit Income (icon) | button | 105 | ✅ REAL | n/a | keep |
| 7.3 | Delete Income (icon) | button | 106 | ✅ REAL | Add confirm | M3 |
| 7.4 | "Stock the Pool" submit | button | 159 | ✅ writes `incomeSources` | n/a | keep |
| 7.F1 | Income form: Label, Amount, Frequency, Status | form | 130–163 | ✅ REAL | Add: person assignment, source type, notes | M3 |
| 7.B1 | ~~Frequency normalization~~ | logic | 36–46 | ✅ Resolved M2 — replaced duplicate display calc with shared `toMonthlyEquivalent` | n/a | done |

---

## Route 8 — Insurance Inspect (`src/routes/InsuranceInspectRoute.tsx`)

| # | Control | Type | Line | Status | Target | Fix |
|---|---|---|---|---|---|---|
| 8.1 | "Execute Inspection" | button | 34 | 🚨 setTimeout + 3 hardcoded quotes | Realistically unavailable | M9 — REMOVE |
| 8.2 | "Register Policy" | button | 69 | ❌ NO-OP no handler | Manual policy CRUD against `insuranceRecords` | M9 — wire up |
| 8.3 | Quote card arrow | button (icon) | 116 | ❌ NO-OP no handler | n/a | M9 — remove with quotes section |

**Route-level notes:**
- Route is L0; rebuild as manual policy CRUD using existing `insuranceRecords` table (which has `&id, householdId, type, expirationDate` indexes — schema is ready). Until M9, HIDE behind disabled feature flag or LABEL the entire route as "Demo."

---

## Route 9 — Ledger Loops (`src/routes/LedgerRoute.tsx`)

| # | Control | Type | Line | Status | Target | Fix |
|---|---|---|---|---|---|---|
| 9.1 | "Scavenge" | button | 106 | 🚨 setTimeout + hardcoded items | Real OCR review queue | **M3 critical — HIDE**; M6 — replace |
| 9.2 | "Bank Sync" | button | 110 | 🚨 setTimeout + 2 hardcoded txns | Real CSV/QFX/OFX import + dedupe | **M3 critical — HIDE**; M5 — replace |
| 9.3 | "+" Add Transaction | button | 114 | ✅ opens modal | n/a | keep |
| 9.4 | Edit Transaction (icon) | button | 151 | ✅ REAL | n/a | keep |
| 9.5 | Delete Transaction (icon) | button | 152 | ✅ REAL | Add confirm | M3 |
| 9.6 | "Commit All" | button | 185 | 🔌 writes mock-scavenged txns | Should not exist until M5/M6 review queues do | **M3 — HIDE with 9.1/9.2** |
| 9.7 | "Discard Telemetry" | button (ghost) | 187 | ✅ clears state | n/a | keep |
| 9.8 | "Commit to Ledger" submit | button | 223 | ✅ writes `transactions` | n/a | keep |
| 9.F1 | Manual txn form: Payee, Amount, Date | form | 205–228 | ✅ REAL | Add: category, type (income/expense), person, notes | M3 |

**Route-level notes:**
- 9.1, 9.2, 9.6 are the second-highest-risk surface (after Vault 6.7). All three write fabricated rows to the real `transactions` table.

---

## Route 10 — Pay Path (`src/routes/PayPathRoute.tsx`)

| # | Control | Type | Line | Status | Target | Fix |
|---|---|---|---|---|---|---|
| 10.1 | "Add Bill" | button | 87 | ✅ opens modal | n/a | keep |
| 10.2 | "Add Debt" | button | 90 | ✅ opens modal | n/a | keep |
| 10.3 | Edit Bill (icon) | button | 114 | ✅ REAL | n/a | keep |
| 10.4 | Delete Bill (icon) | button | 115 | ✅ REAL | Add confirm | M3 |
| 10.5 | Edit Debt (icon) | button | 143 | ✅ REAL | n/a | keep |
| 10.6 | Delete Debt (icon) | button | 144 | ✅ REAL | Add confirm | M3 |
| 10.7 | Bill submit | button | 161 | ✅ writes `bills` | n/a | keep |
| 10.8 | Debt submit | button | 172 | ✅ writes `debts` | n/a | keep |
| 10.F1 | Bill form: Label, Amount, Due Day | form | 154–163 | ✅ REAL | Add: category, autopay flag, owner, required-vs-optional | M3 |
| 10.F2 | Debt form: Label, Balance, Min Payment | form | 165–174 | ✅ REAL | Add: interest rate, due day, owner | M3 |

**Route-level notes:**
- M3 adds a "Due Soon" view (next 14 days). M8 adds extra-payment planner. Schema indexes on `dueDay` are already present.

---

## Route 11 — Reports Arena (`src/routes/ReportsRoute.tsx`)

| # | Control | Type | Line | Status | Target | Fix |
|---|---|---|---|---|---|---|
| 11.1 | "Export" | button | 35 | ⚠️ alert-only | Real CSV + JSON export, multi-report selection | M4 |
| 11.2 | "Execute Print" | button | 38 | ✅ `window.print()` | Add print stylesheet for clean output | M4 |

**Route-level notes:**
- Reports content is currently a static text layout in `GlassCard` (line 45). M4 expands to multiple report types (monthly household, debt, savings, tax-summary, document-inventory) selectable via tabs or a select.

---

## Route 12 — Settings (`src/routes/SettingsRoute.tsx`)

| # | Control | Type | Line | Status | Target | Fix |
|---|---|---|---|---|---|---|
| 12.1 | Theme buttons (10 variants) | toggle | 101–110 | ✅ REAL via theme provider | Persist selection (currently theme provider may rehydrate but verify) | M3 |
| 12.2 | "Export Backup" | button | 123 | ✅ REAL `exportDatabaseToJson` | Add `schemaVersion` to payload | M4 |
| 12.3 | "Restore from JSON" | button + file input | 128 | ✅ REAL `importDatabaseFromJson` | Add diff preview before commit + version check | M4 |
| 12.4 | "Save Preferences" | button | 88 | ⚠️ alert-only | Persist all toggles to `preferences` table or localStorage | M3 |
| 12.5 | Bill Due Reminders toggle | toggle | 169 | ❌ NO-OP no handler | Persist + wire to notification system | M3 (persist) / M9 (notifications) |
| 12.6 | Budget Deficit Warnings toggle | toggle | 173 | ❌ NO-OP no handler | Persist + wire to Mission Control | M3 |
| 12.7 | Biometric Auth row | display | 186 | ❌ "PLATFORM ONLY" label | Capacitor biometric plugin | M9 |
| 12.8 | Sensitive Value Masking toggle | toggle | 191 | ❌ NO-OP no handler | Persist + wire to amount-render helper | M3 |
| 12.9 | Auto-Categorize Payees toggle | toggle | 205 | ❌ NO-OP no handler | Persist + wire to merchant rules engine | M3 (persist) / M5 (engine) |
| 12.10 | Predictive Stash Mapping toggle | toggle | 209 | ❌ NO-OP no handler | Persist + wire to forecasting | M3 (persist) / M8 (forecast) |
| 12.11 | "Local LLM" provider button | toggle | 222 | ✅ REAL state | Persist to `aiConfig` | M3 |
| 12.12 | "Cloud API" provider button | toggle | 231 | ✅ REAL state | Persist to `aiConfig` | M3 |
| 12.13 | Local Endpoint input | form-field | 244 | ✅ REAL state | Persist to `aiConfig` | M3 |
| 12.14 | API Key input (password) | form-field | 255 | ✅ REAL state | Persist to `aiConfig` (consider obfuscation in db) | M3 |
| 12.15 | Model Identifier input | form-field | 265 | ❌ no state binding visible | Wire to state + persist to `aiConfig` | M3 |
| 12.16 | "Wipe Local Database" | button (destructive) | 321 | ✅ REAL `clearDatabase` | Add backup-first prompt | M4 |
| 12.17 | "Reset to Demo State" | button | 324 | ✅ REAL seed | Add backup-first prompt | M4 |
| 12.F1 | Multi-Currency form | form | 145–153 | ❌ no state binding | Either wire to `preferences` or REMOVE | M3 — REMOVE if not used |

**Route-level notes:**
- 7 of the toggles (12.5, 12.6, 12.7, 12.8, 12.9, 12.10, plus 12.15 input) have NO `onClick`/`onChange` handler at all. M3 must wire every toggle or remove it.
- Settings is the only route NOT using `PageHeader` (uses a custom header at line 83). M3 standardizes.
- Settings does NOT use `GlassCard` (uses a `Card` component instead). M3 decides whether `Card` is the new pattern or migrate to `GlassCard`.

---

## Route 13 — Stash Map (`src/routes/StashMapRoute.tsx`)

| # | Control | Type | Line | Status | Target | Fix |
|---|---|---|---|---|---|---|
| 13.1 | "+" Add Goal | button | 69 | ✅ opens modal | n/a | keep |
| 13.2 | Edit Goal (icon) | button | 95 | ✅ REAL | n/a | keep |
| 13.3 | Delete Goal (icon) | button | 96 | ✅ REAL | Add confirm | M3 |
| 13.4 | "Commit to Map" submit | button | 126 | ✅ writes `savingsGoals` | n/a | keep |
| 13.F1 | Goal form: Label, Target, Current, Monthly, Deadline | form | 117–128 | ✅ REAL | Add: priority, person/owner, category | M3 |
| 13.C1 | Progress bars | display | 105 | ✅ REAL `(current/target)*100` | Add: required-monthly-contribution calc, on-track/underfunded label | M3 (label) / M8 (scenario) |

---

## Route 14 — Subscriptions Shelf (`src/routes/SubscriptionsShelfRoute.tsx`)

| # | Control | Type | Line | Status | Target | Fix |
|---|---|---|---|---|---|---|
| 14.1 | "+" Add Subscription | button | 120 | ✅ opens modal | n/a | keep |
| 14.2 | Edit Subscription (icon) | button | 145 | ✅ REAL | n/a | keep |
| 14.3 | Delete Subscription (icon) | button | 146 | ✅ confirms + REAL | n/a | keep |
| 14.4 | "Cancel Protocol" | button | 163 | ✅ opens template modal | n/a | keep |
| 14.5 | "Dispute" | button | 167 | ✅ opens template modal | n/a | keep |
| 14.6 | Subscription submit | button | 221 | ✅ writes `subscriptions` | n/a | keep |
| 14.7 | "Copy Protocol" | button | 235 | ⚠️ alert after copy (cosmetic) | Replace alert with toast | M3 |
| 14.8 | "Execute Email" | button | 238 | ✅ `mailto:` link | n/a | keep |
| 14.F1 | Subscription form: Service, Cost, Cycle, Owner, Email | form | 190–225 | ✅ REAL | Add: renewal date, price-change history | M3 / M8 |

**Route-level notes:**
- This route is genuinely complete. Only cosmetic toast upgrade needed.

---

## Route 15 — Tax Taxi (`src/routes/TaxTaxiRoute.tsx`)

| # | Control | Type | Line | Status | Target | Fix |
|---|---|---|---|---|---|---|
| 15.1 | Tracker tab | tab | 100 | ✅ REAL | n/a | keep |
| 15.2 | Forms tab | tab | 110 | ✅ REAL | n/a | keep |
| 15.3 | "+" Add Tax Year | button | 127 | ✅ opens modal | n/a | keep |
| 15.4 | Edit Tax Record (icon) | button | 166 | ✅ REAL | n/a | keep |
| 15.5 | Delete Tax Record (icon) | button | 167 | ✅ REAL | Add confirm | M3 |
| 15.6 | Tax Record submit | button | 265 | ✅ writes `taxRecords` | n/a | keep |
| 15.7 | Form library buttons (1040, W-2, 1099-NEC) | toggle | 204–215 | ✅ REAL state | n/a | keep |
| 15.8 | "Discard" | button | 237 | ✅ REAL clears state | n/a | keep |
| 15.9 | "Commit Draft" | button | 238 | ⚠️ writes 2-field placeholder + alert | Real form fields per document type | M8 — build proper fields OR LABEL "manual notes" |
| 15.F1 | Tax Record form: Year, Owner, Owed, Paid | form | 254–266 | ✅ REAL | Add: filing status, refund amount, notes | M3 |
| 15.F2 | Tax Form Draft: Entity, Gross | form | 232–240 | ⚠️ placeholder fields only | Real per-form-type field set | M8 |
| 15.C1 | Tax Trajectory BarChart | chart | 133–141 | ✅ REAL liability vs withheld | n/a | keep |

---

## BeaconChatbot (`src/components/BeaconChatbot.tsx`)

| # | Control | Type | Line | Status | Target | Fix |
|---|---|---|---|---|---|---|
| C.1 | Toggle FAB | button | 74 | ✅ REAL | n/a | keep |
| C.2 | Clear Chat (icon) | button | 91 | ✅ REAL `db.chatMessages.clear` | n/a | keep |
| C.3 | Message input | form-field | 134 | ✅ REAL | n/a | keep |
| C.4 | Send | button | 141 | 🚨 user msg real, bot reply is setTimeout + canned if/else | Real provider via `aiConfig` | **M3 — LABEL "Demo"**; M7 — replace |
| C.5 | Quick suggestion buttons (Analyze / Initiate / Check) | button | 146 | ✅ REAL pre-fill | Wire to real assistant intents post-M7 | M7 |

---

## Cross-cutting — Component-reuse map

| Component | Adopted | Missing in | Action |
|---|---|---|---|
| `PageHeader` | 14/15 routes | `SettingsRoute` (custom header at line 83) | M3 — migrate Settings or document deviation |
| `GlassCard` | 14/15 routes + chatbot | `SettingsRoute` uses `Card` | M3 — decide canonical card primitive |
| `EmptyState` | 8/15 routes | Beacon Bridge, Mission Control, Dashboard, Income (partial), Pay Path, Reports, Settings | M3 — add to remaining 7 |
| `BeaconModal` | 11/15 routes | Beacon Bridge, Mission Control, Dashboard, Insurance Inspect, Reports, Settings | n/a — these don't need modals |
| `AgenticTooltip` | 2 instances (Dashboard only) | All other routes | M3+ — sparingly add where metric explanation helps; do NOT spread for theater |

**Decision needed (M3 design review):** Is `GlassCard` or `Card` the canonical card primitive? Settings uses `Card`; everything else uses `GlassCard`. Pick one and migrate.

---

## Cross-cutting — Empty / loading / error state matrix

| Route | Loading state | Empty state | Error state |
|---|---|---|---|
| Beacon Bridge | ✅ "Synchronizing..." | ❌ | ❌ |
| Mission Control | ✅ "Synchronizing..." | ❌ | ❌ |
| Credit | ✅ "Opening Credit Vault..." | ❌ no `EmptyState` for snapshot list | ❌ |
| Dashboard | ✅ "Synchronizing Cockpit..." | ❌ | ❌ |
| Debt Center | ✅ "Opening Debt Center..." | ✅ EmptyState | ❌ |
| Document Store | ✅ "Accessing The Vault..." | ✅ EmptyState | ⚠️ `alert("Failed to store document.")` |
| Income | ✅ "Scanning..." | ✅ EmptyState | ❌ |
| Insurance Inspect | ❌ no loading | ✅ EmptyState (pre-inspection) | ❌ |
| Ledger | ✅ "Opening Ledger..." | ✅ EmptyState | ❌ |
| Pay Path | ✅ "Mapping..." | ❌ | ❌ |
| Reports | ✅ "Compiling..." | ❌ | ❌ |
| Settings | ❌ no loading | ❌ | ⚠️ inline text on import (line 133–134) |
| Stash Map | ✅ "Synchronizing Stash..." | ✅ EmptyState | ❌ |
| Subscriptions | ✅ "Dusting..." | ✅ EmptyState | ❌ |
| Tax Taxi | ✅ "Summoning..." | ✅ EmptyState (×2) | ❌ |

**Action (M3):**
- Add `EmptyState` to: Beacon Bridge, Mission Control, Credit (snapshot list), Dashboard (no-data day), Pay Path, Reports.
- Add error toast/banner system to all routes.
- Add loading state to Insurance Inspect and Settings.
- Replace inline `alert()` in Document Store and Subscriptions with toast.
- Add `ErrorBoundary` at app root and per-route fallback (M2).

---

## Cross-cutting — Mobile / Android parity matrix

(Initial assessment from code reading; per-route on-device pass scheduled in M9.)

| Route | Hit-target risk (icon-only buttons) | Modal mobile fit | Form scroll/keyboard | Chart responsiveness |
|---|---|---|---|---|
| Beacon Bridge | low | n/a (no modal) | n/a | n/a |
| Mission Control | low | n/a | n/a | custom SVG — verify scaling |
| Credit | medium (delete icon, edit icon) | M3 — verify modal max-h | M3 — keyboard avoidance | Recharts — usually OK |
| Dashboard | low | n/a | n/a | AreaChart — verify viewport |
| Debt Center | medium | M3 verify | M3 verify | Recharts |
| Document Store | medium | M3 verify | file picker on Android | n/a |
| Income | medium | M3 verify | M3 verify | n/a |
| Insurance Inspect | low | n/a | n/a | n/a |
| Ledger | medium | M3 verify | M3 verify | n/a |
| Pay Path | medium (×2 modals) | M3 verify | M3 verify | n/a |
| Reports | low | n/a | n/a | n/a |
| Settings | low | n/a | password input on Android | n/a |
| Stash Map | medium | M3 verify | date picker on Android | progress bars |
| Subscriptions | medium | M3 verify (×2 modals) | M3 verify | n/a |
| Tax Taxi | medium | M3 verify | M3 verify | BarChart |

**M3 mobile checklist (per route with medium risk):**
1. Icon-only buttons must be ≥ 44×44 px tap target (or wrap in larger pressable area).
2. Modals must respect viewport `max-h` and have scrollable body when keyboard opens.
3. Date / number inputs must use native pickers on Android (verify `inputmode`).
4. Charts must use `<ResponsiveContainer>` (Recharts) — verify all 7 chart instances.

**M9 Android device test:** smoke every route on physical device, screenshot at small viewport, verify safe-area on status bar + bottom nav.

---

## Highest-priority controls (M3 must-fix list)

Ordered by user-visible harm:

1. **Vault 6.7 "Commit to App"** — writes mock-extracted records to real db on one click. **DISABLE in M3.**
2. **Ledger 9.1 / 9.2 / 9.6** — Bank Sync + Scavenge + Commit-All write fabricated transactions. **HIDE/LABEL in M3.**
3. **Credit 3.1 / 3.2** — Bank Fetch + Credit Check write `Math.random` scores. **REMOVE in M3.**
4. **Beacon Bridge 1.1 / 1.2** — Scan + Merge write fake `syncLogs`. **HIDE/LABEL in M3.**
5. **Insurance 8.1 / 8.2 / 8.3** — All quotes hardcoded; route is L0. **LABEL whole route as Demo in M3.**
6. **Settings 12.4 + 12.5–12.10 + 12.15** — Save Preferences alerts only; 7 toggles + Model input have no handler. **WIRE in M3.**
7. **Mission Control 2.1 / 2.2 / 2.3** — Persist Plan alert; hardcoded Stability Index + forecast. **REMOVE 2.1; CALCULATE 2.2 + 2.3 in M3.**
8. **Dashboard 4.2 / 4.5** — Save Cockpit alert; Execute Deep Audit no-op. **REMOVE both in M3.**
9. **Reports 11.1** — Export alerts. **Move to M4 real export; until then LABEL "M4 — coming soon."**
10. **Chatbot C.4** — bot replies are canned. **LABEL "Demo" in M3; M7 replaces.**

## What this checklist enables

- **M2** uses items marked M2 (income biweekly fix; budget engine + import schema test coverage; `npm test` script).
- **M3** has a concrete punch list (above).
- **M4–M9** each milestone owns its rows. No control is unassigned.

## Re-audit trigger

Re-run this enumeration after any milestone that touches a route file. Audit script suggestion (M2 deliverable): a `tools/audit-controls.ts` that greps for `setTimeout`, `Math.random`, `alert(`, and `onClick={}` (empty handler) under `src/routes/` and `src/components/`, and fails if counts increase.
