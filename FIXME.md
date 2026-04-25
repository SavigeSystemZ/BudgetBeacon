# FIXME

> **Truth Reset — 2026-04-25.** Previous file said "None recorded." Audit on 2026-04-25 surfaced the following itemized issues. All entries have file:line evidence and are actionable.

Use this file for unresolved problems that materially affect delivery confidence, correctness, reliability, security, or maintainability.

## Entry format

- Severity:
- Area:
- Problem:
- Impact:
- Temporary mitigation:
- Permanent fix:
- Validation gap:
- Owner or next step:

---

## Mocked / simulated user-facing surfaces (the "trust gap")

### Mocked AI chatbot
- **Severity:** High
- **Area:** AI assistant (`src/components/BeaconChatbot.tsx:44-62`)
- **Problem:** `setTimeout(1500)` + canned `if/else` responses pretending to be an LLM. No provider call.
- **Impact:** Misleads the user about app capability; any "analysis" is fabricated.
- **Temporary mitigation:** Label the chatbot "Demo / Coming Soon" until M7.
- **Permanent fix:** M7 — provider abstraction with local Ollama default.
- **Validation gap:** No way to verify "AI" output today.
- **Owner / next step:** Defer to M7; in M3, label honestly.

### Mocked Ledger Bank Sync
- **Severity:** High
- **Area:** Ledger (`src/routes/LedgerRoute.tsx:53-62`)
- **Problem:** "Bank Sync" button uses `setTimeout(2500)` then writes 2 hardcoded transactions (Starbucks $5.45, Amazon $42.99).
- **Impact:** Inserts fabricated transactions into the user's real ledger. **Data corruption risk.**
- **Temporary mitigation:** Remove or disable the button immediately in M3 if M5 is delayed.
- **Permanent fix:** M5 — real CSV/QFX/OFX import with dedupe and review queue.
- **Validation gap:** No deduplication; re-clicking re-inserts the fakes.
- **Owner / next step:** **CRITICAL** — address in M3 even if it means just hiding the button.

### Mocked Ledger Scavenge
- **Severity:** High
- **Area:** Ledger (`src/routes/LedgerRoute.tsx:65-78`)
- **Problem:** Scavenge button uses `setTimeout(3000)` + 2 hardcoded items (Rent $1200, Work Bonus $500).
- **Impact:** Same as Bank Sync — fabricated transactions written to real ledger.
- **Temporary mitigation:** Hide button in M3.
- **Permanent fix:** M6 — real OCR + extraction review.

### Mocked Document Scavenge
- **Severity:** High
- **Area:** Document Store (`src/routes/DocumentStoreRoute.tsx:74-84`)
- **Problem:** Scavenge returns hardcoded `[{type:"income", label:"Monthly Benefit", amount:1450}, {type:"bill", label:"Premium Deduction", amount:174.70}]` after `setTimeout(3000)`. `applyScavengedData` writes these as real income / bill records.
- **Impact:** Fake VA-shaped data committed to real db without review.
- **Temporary mitigation:** Disable Apply button until M6.
- **Permanent fix:** M6 — Tesseract.js OCR + per-field confidence + review-before-commit.

### Mocked Credit Bank Fetch / Credit Check
- **Severity:** Medium
- **Area:** Credit (`src/routes/CreditRoute.tsx:57-74`)
- **Problem:** Both buttons generate fake scores via `Math.floor(Math.random() * (850 - 600) + 600)` after a `setTimeout`.
- **Impact:** Fake credit scores written to `creditSnapshots`.
- **Temporary mitigation:** Remove the two buttons in M3; manual snapshot entry is real and sufficient.
- **Permanent fix:** M8 — either real bureau integration (unlikely available) or remove permanently.

### Mocked Beacon Bridge sync
- **Severity:** Medium
- **Area:** Beacon Bridge (`src/routes/BeaconBridgeRoute.tsx:21, 28-37`)
- **Problem:** Hardcoded "Partner's Phone (iPhone 15)" device. `setTimeout(3500)` writes one fake `syncLogs` row with `1024 * 45` bytes hardcoded payload then alerts "Household telemetry unified."
- **Impact:** No data is actually synced; `syncLogs` table accumulates fake entries.
- **Temporary mitigation:** Disable in M3; recommend Settings → Export/Import as the real sync path.
- **Permanent fix:** M9 — start from signed export/import bundles; defer P2P/WebRTC.

### Mocked Insurance Inspect
- **Severity:** Medium
- **Area:** Insurance Inspect (`src/routes/InsuranceInspectRoute.tsx:16-26, 55-67`)
- **Problem:** "Execute Inspection" returns hardcoded Progressive/Geico/State Farm quotes. "Active Shield" section shows hardcoded $245 monthly premium.
- **Impact:** Misleads the user about market data.
- **Temporary mitigation:** Replace fake quotes section with manual policy CRUD using the existing `insuranceRecords` table.
- **Permanent fix:** M9 — manual CRUD or hide behind disabled flag.

### Alert-only "save" buttons
- **Severity:** Medium
- **Area:** multiple
- **Problem:** Three primary-action buttons only fire `alert()` and persist nothing:
  - `DashboardRoute.tsx:76` — "Save Cockpit"
  - `BudgetMissionControlRoute.tsx:32` — "Persist Plan"
  - `ReportsRoute.tsx:35` — "Export"
  - `SettingsRoute.tsx:64-66` — "Save All"
- **Impact:** User believes work is saved; nothing is.
- **Temporary mitigation:** Disable buttons or label "(coming in M3/M4)".
- **Permanent fix:** M3 (Save Cockpit, Persist Plan, Save All); M4 (Reports Export).

### Hardcoded "Stability Index" and forecast text
- **Severity:** Medium
- **Area:** Mission Control (`src/routes/BudgetMissionControlRoute.tsx:102-103, 169`)
- **Problem:** Stability Index is `85` if margin positive else `45`. Forecast text "65% complete... by August 2026" is a string literal.
- **Impact:** User trusts these numbers as calculated.
- **Permanent fix:** M3 — calculate from `calculateBudgetSummary` and savings velocity.

### Settings UI toggles do not persist
- **Severity:** Medium
- **Area:** Settings (`src/routes/SettingsRoute.tsx:168-209`)
- **Problem:** Theme/notification/security/automation toggles render and toggle in-memory but write nothing.
- **Impact:** Configuration is lost on reload.
- **Permanent fix:** M3 — persist to db (preferences table) or localStorage. Theme already works via theme-provider.

### AI Config form does not persist
- **Severity:** Medium
- **Area:** Settings (`src/routes/SettingsRoute.tsx:241-266`)
- **Problem:** Form accepts endpoint/key but does not write to the existing `aiConfig` Dexie table or validate.
- **Impact:** Will block M7 work; AI provider config is unrecoverable across sessions.
- **Permanent fix:** M3 — wire form to `aiConfig` table.

### Tax Taxi form is a placeholder
- **Severity:** Medium
- **Area:** Tax Taxi (`src/routes/TaxTaxiRoute.tsx:233-234`)
- **Problem:** Form has only "Entity / Payer" and "Gross Telemetry" fields; not a real tax form.
- **Impact:** No real tax document captured.
- **Permanent fix:** M8 — build proper form fields OR re-label as "manual draft assist" with notes capture.

---

## Infrastructure / quality gaps

### ~~No `npm test` script~~ — resolved M2 (2026-04-25)
- M0 audit said "no test files exist"; this was wrong. 17 tests already existed (`budget-engine.test.ts`, `stash-map.calculations.test.ts`). M2 added the missing `test`/`test:watch` scripts + `vitest.config.ts` + `vitest.setup.ts` + a 5-case backup round-trip test.

### ~~No `typecheck` script~~ — resolved M2 (2026-04-25)
- Added `"typecheck": "tsc -b --noEmit"`.

### ~~No error boundaries~~ — resolved M2 (2026-04-25)
- Added `src/components/ErrorBoundary.tsx`; wired root + per-route in `src/App.tsx`. Each per-route boundary names the route on the fallback UI.

### ~~Income biweekly factor is approximate~~ — resolved M2 (2026-04-25)
- The bug was *not* in the budget engine — `src/modules/budget-engine/frequency.ts` already used `(amount * 52) / 12 ≈ 2.1667`. The bug was a *duplicate* display calc in `src/routes/IncomeRoute.tsx:36-46` that used `2.16` for biweekly and `4.33` for weekly and ignored `semimonthly`/`custom` entirely. M2 replaced it with a call to the shared `toMonthlyEquivalent`.

### ~~Backup format unversioned~~ → corrected and superseded by completeness fix (M2)
- Original `exportJson.ts` already had `version: 1`; the M0 risk wording was imprecise. The real bug surfaced in M2: backup only included 8 of 18 db tables, silently dropping `subscriptions`, `taxRecords`, `taxTransactions`, `taxForms`, `aiConfig`, `chatMessages`, `insuranceRecords`, `syncLogs`, `debtTransactions`. M2 bumped to v2 with all 17 JSON-serializable tables. v1 backups still validate. `documents` (Blob) is the only excluded table — base64 round-trip deferred to M4.

### `applyScavengedData` writes without review
- **Severity:** High
- **Area:** Document Store (`src/routes/DocumentStoreRoute.tsx:87-99`)
- **Problem:** Mock-extracted data is committed to db on a single click, no review step.
- **Impact:** Even after M6 makes extraction real, this commit-without-review pattern is unsafe.
- **Permanent fix:** M6 — insert a review-before-commit step.

### Documentation drift (resolved by M0 but watch-listed)
- **Severity:** Low (now resolved)
- **Area:** Planning docs
- **Problem:** PLAN, TODO, WHERE_LEFT_OFF, ROADMAP previously claimed completion that the runtime did not have.
- **Mitigation:** M0 (this commit) reset all six planning docs.
- **Watch:** If any future doc drifts back to "Mission Ready" / "fully delivered" without runtime evidence, treat as a regression.

---

## Deferred Improvements

- Setup automated CI/CD for distribution if scaling beyond local host.
- Push to remote once git credentials are authenticated on the host.

## Blockers

- None currently. M0 is doc-only; no runtime preconditions for M1.

## Usage rules

- This file is for unresolved problems, not wish-list ideas.
- If a risk changes delivery confidence, cross-link it from `WHERE_LEFT_OFF.md` and `RISK_REGISTER.md`.
- Every new entry must have a file:line reference if it points at code.
