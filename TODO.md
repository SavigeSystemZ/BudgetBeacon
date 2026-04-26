# TODO

> **Truth Reset — 2026-04-25.** Previous TODO marked M3–M8 complete. Audit on 2026-04-25 showed multiple of those surfaces still simulated. Inflated `[x]` items have been moved to "Previously claimed complete (needs re-verification)" below. Real work queue follows.

This is the active execution queue. Keep it tight, factual, and ordered.
Use priority signals: **CRITICAL**, **HIGH**, **MEDIUM**, **LOW**.

## Current Priority

- [x] **CRITICAL: M0 — Repo Truth Reset.** Rewrite `PLAN.md`, `ROADMAP.md`, `WHERE_LEFT_OFF.md`, `TODO.md`, `FIXME.md`, `RISK_REGISTER.md`. Create `docs/GUI_COMPLETION_MAP.md` and `docs/INTEGRATIONS_STRATEGY.md`. *(Completed 2026-04-25.)*
- [x] **CRITICAL: M1 — GUI Surface Audit & Completion Matrix.** Created `docs/GUI_COMPLETION_CHECKLIST.md` with per-control inventory (~140 buttons + ~80 form fields), component-reuse map, empty/loading/error state matrix, mobile/Android parity matrix, and ordered M3 must-fix list. *(Completed 2026-04-25.)*
- [x] **CRITICAL: M2 — Core Data + Validation Hardening.** Added test/typecheck/audit-controls scripts, vitest config, ErrorBoundary, IncomeRoute frequency drift fix, backup completeness fix (v2 format covers all 17 JSON-serializable tables; documents/Blob deferred to M4), backup round-trip test. 22 tests passing, typecheck clean. *(Completed 2026-04-25.)*
- [x] **CRITICAL: M3 (substantial) — Full GUI Completion Pass.** Two commits (`72c86c3` + `ae1bbb5`). All 10 highest-priority must-fix items done. Audit counts: `setTimeout` 10→2 (legit UX), `mathRandom` 2→0, `alert` 15→0. New shared primitives: `featureFlags` map, `DemoBadge` component, `preferences` localStorage layer, `stabilityIndex` module + 7 tests. 29 tests passing. Insurance Inspect now real manual CRUD; Settings now persists toggles + aiConfig. *(Completed 2026-04-25.)*

## Immediate Queue (M4 — Reports, Backup, Restore, Recovery)

- [ ] **HIGH:** Documents-table backup completion — base64-encode Blob on export, decode on import. Bump backup format to v3 (v1 + v2 still accepted). Add round-trip test for documents in `backup.test.ts`.
- [ ] **HIGH:** Real Reports Export — flip `featureFlags.reportsRealExport` once a real implementation lands. CSV per entity + JSON full-backup shortcut + per-report views (monthly household, debt summary, savings progress, tax-year packet, document inventory).
- [ ] **HIGH:** Restore-confirmation diff preview — before commit, show counts being added vs replaced.
- [ ] **MEDIUM:** Print stylesheet pass — Reports `window.print()` works but layout isn't optimized for paper.

### M3 polish carry-over (low-risk, do during M4 or M5)
- [ ] **MEDIUM:** Add `EmptyState` component to remaining 6 routes (Mission Control, Dashboard, Pay Path, Credit snapshot list, Reports, plus the existing IncomeRoute partial).
- [ ] **LOW:** Add delete-confirm modal helper and apply to all icon-button deletes (Income/Pay Path bills/Pay Path debts/Stash Map/Subscriptions/Tax Taxi/Credit/Documents).
- [ ] **LOW:** Accessibility audit (color contrast, focus order, aria-labels on icon-only buttons).
- [ ] **LOW:** Decide on canonical Card primitive (`GlassCard` vs `Card`); migrate Settings to match the rest of the app.

## Reference Queue (was M2; now done)

- [x] **HIGH:** Added `test`/`test:watch`/`typecheck`/`audit:controls` scripts. *(M2 done.)*
- [x] **HIGH:** Created `vitest.config.ts` + `vitest.setup.ts`. Verified pre-existing tests (budget-engine 12 + stash-map 5 = 17). Added backup round-trip test (5 cases). Total 22. *(M2 done.)*
- [x] **HIGH:** Fixed `src/routes/IncomeRoute.tsx:36-46` — was a duplicate display calc with `2.16`/`4.33`; now calls shared `toMonthlyEquivalent` from `frequency.ts`. Engine itself was already correct. *(M2 done.)*
- [x] **HIGH:** Verified Zod schemas at every existing CRUD boundary; added inline schemas in `importJson.ts` for the 9 new tables added to the v2 backup. *(M2 done.)*
- [x] **MEDIUM:** Added `ErrorBoundary` component; root + per-route in `src/App.tsx`. *(M2 done.)*

## M3 — Full GUI Completion Pass (queued)

- [ ] **HIGH:** Replace `alert("Snapshot saved.")` in `DashboardRoute.tsx:76` with real persistence or remove the button.
- [ ] **HIGH:** Replace `alert("Strategic plan saved.")` in `BudgetMissionControlRoute.tsx:32` with real persistence or remove.
- [ ] **HIGH:** Replace hardcoded Stability Index in `BudgetMissionControlRoute.tsx:102-103` with real calculation from budget summary.
- [ ] **HIGH:** Replace hardcoded forecast text in `BudgetMissionControlRoute.tsx:169` with calculated savings velocity.
- [ ] **HIGH:** Replace `alert("Report Exported.")` in `ReportsRoute.tsx:35` with real export (deferred to M4 — leave as TODO link until then, do NOT keep the alert).
- [ ] **HIGH:** Persist Settings UI toggles (`SettingsRoute.tsx:168-209`) to db or localStorage; replace `handleSaveAll` alerts.
- [ ] **HIGH:** Persist `aiConfig` from `SettingsRoute.tsx:241-266` to the existing `aiConfig` Dexie table.
- [ ] **HIGH:** Add real Tax Taxi form fields (`TaxTaxiRoute.tsx:233-234`) — at minimum filer info, income type, amount, withholding, year — or honestly label as "manual draft assist."
- [ ] **MEDIUM:** Loading + empty + error states audit per route; fill gaps.
- [ ] **MEDIUM:** Mobile safe-area pass (Android viewport).

## M4 — Reports, Backup, Restore, Recovery (queued)

- [ ] **HIGH:** Real CSV export for transactions, bills, debts, goals.
- [ ] **HIGH:** Real JSON export with versioned schema (`schemaVersion` field) and migration tolerance on import.
- [ ] **HIGH:** Restore-confirmation flow with diff preview before commit.
- [ ] **HIGH:** Backup round-trip integrity test (export → wipe → import → verify equal).
- [ ] **MEDIUM:** Real PDF report (or proper print-CSS layout for `window.print()` path).

## M5 — Ledger + Bank/Data Import Foundation (queued)

- [ ] **HIGH:** Remove or feature-flag-OFF mocked Bank Sync (`LedgerRoute.tsx:53-62`).
- [ ] **HIGH:** Real CSV import for transactions: file picker → parse → map columns → dedupe (by date+amount+payee) → review queue → commit.
- [ ] **MEDIUM:** QFX/OFX parser (libofx-style) scaffolded.
- [ ] **MEDIUM:** Merchant/payee normalization rules (configurable map).

## M6 — Vault + OCR + Extraction Review (queued)

- [ ] **HIGH:** Remove mocked Scavenge (`DocumentStoreRoute.tsx:74-84`, `LedgerRoute.tsx:65-78`).
- [ ] **HIGH:** Tesseract.js (or equivalent) browser-side OCR for uploaded PDFs/images.
- [ ] **HIGH:** Extraction-review UI: confidence per field, edit before commit, link extracted records back to source document via provenance pointer.

## M7 — AI Assistant Real Integration (queued)

- [ ] **HIGH:** Replace mocked chatbot in `BeaconChatbot.tsx:44-62` with provider abstraction.
- [ ] **HIGH:** Local provider first (Ollama / OpenAI-compatible local endpoint).
- [ ] **MEDIUM:** Cloud provider opt-in (Anthropic / OpenAI), clearly labeled non-local.
- [ ] **HIGH:** All assistant action proposals require explicit user confirmation before db writes.

## M8 — Tax / Credit / Debt / Household Planning Deepening (queued)

- [ ] **HIGH:** Remove mocked Credit Bank Fetch + Credit Check (`CreditRoute.tsx:57-74`); keep manual snapshot UX as the honest baseline.
- [ ] **HIGH:** Avalanche vs snowball debt strategy comparison in Debt Center.
- [ ] **MEDIUM:** Cross-module household planning summary (Mission Control rebuild on real data).

## M9 — Android / Web Final Polish + RC (queued)

- [ ] **HIGH:** Remove or replace mocked Beacon Bridge (`BeaconBridgeRoute.tsx:28-37`); start from real export/import bundle path before any peer/WebRTC work.
- [ ] **HIGH:** Remove mocked Insurance Inspect (`InsuranceInspectRoute.tsx:16-26, 55-67`); replace with manual policy CRUD or hide behind disabled feature flag.
- [ ] **HIGH:** Android safe-area + APK smoke test on real device.
- [ ] **HIGH:** Install/recovery docs.
- [ ] **HIGH:** Release checklist passes.

## Maintenance / Low-priority

- [ ] **LOW:** Push to remote once git credentials are authenticated on the host.
- [ ] **LOW:** CI/CD setup if scaling beyond local host.

## Data-quality items (pre-existing, still valid)

- [ ] **MEDIUM:** Verification of VA Assistance Seed Data (exact values for property tax, SimpliSafe, Aaron's, etc.).
- [ ] **MEDIUM:** Attach Kehley M. Smith's Market Basket pay stubs and SNAP/food benefit verification.
- [ ] **MEDIUM:** Attach official SSDI/SSA benefit letter when available.
- [ ] **MEDIUM:** Update current bank balances before submitting any means-tested asset disclosure.
- [ ] **MEDIUM:** Confirm exact Aaron's monthly payment and balance from statement.
- [ ] **MEDIUM:** Confirm SimpliSafe actual monthly amount ($10 vs $30).
- [ ] **MEDIUM:** Confirm exact property tax monthly equivalent and any veteran tax credit/abatement options.

## Previously claimed complete (needs re-verification — DO NOT mark `[x]` without evidence)

These items were marked complete in the prior TODO. The 2026-04-25 audit showed several were inflated. Each must be re-verified against current code before being re-marked.

- [ ] **Re-verify:** "M3 — Budget Engine." Reality: `calculateBudgetSummary` exists and is real aggregation, but no Vitest coverage exists. Re-mark only after M2 adds tests.
- [ ] **Re-verify:** "M4 — Beacon Dashboard." Reality: Dashboard renders real data but has `alert("Snapshot saved.")` dead control. Re-mark after M3.
- [ ] **Re-verify:** "M5 — Stash Map Forecasting." Reality: progress is `(current/target)*100`; no real forecasting. Re-scope or re-mark after M8.
- [ ] **Re-verify:** "M6 — Credit Snapshot + Reports." Reality: Credit snapshots real, but Bank Fetch / Credit Check are `Math.random` mocks; Reports Export is `alert()`. Re-mark after M4 + M8.
- [ ] **Re-verify:** "M7 — Backup + Polish + Hardening." Reality: backup export/import real, but no round-trip test, no error boundaries, no settings persistence. Re-mark after M2 + M4.
- [ ] **Re-verify:** "M8 — Final Polish (Dark Mode + PWA)." Re-mark after M9 release-candidate pass.

## Genuinely-complete items (kept from prior TODO)

These are honest:
- [x] Implemented Ledger & Transactions actual-spending tracker (manual entry).
- [x] Fixed Android APK routing, assets, and VA seed data injection.
- [x] Overhauled Mobile UX (Bottom Nav, Transparent Status Bar, Safe Areas) — re-verify safe areas in M9.
- [x] Cross-platform Packaging (Android APK via Capacitor, Windows .exe config via Electron).
- [x] Overhauled UI with "Immersive Deep Glass" aesthetic.
- [x] Generated and exported VA Assistance Seed Data to `va-assistance-seed.json`.
- [x] Tailored meta-system for Budget Beacon.
- [x] Project Wrap-up. Git initialized.
- [x] Advanced Installer. `install.sh` and install to `/home/whyte/.local/bin`.
- [x] M2 — Income + Pay Path + Stash Map Forms (CRUD real).
- [x] M1 — Data Model + Local Storage (Dexie v4 active).
- [x] M0 — Scaffold Budget Beacon.

## Usage rules
- Keep this file current enough that another tool can pick up immediately.
- Use priority signals so the next agent knows what to work on first.
- Mark items `[x]` only when fully done, not "mostly done."
- If you remove a mock, log the file:line removed in the commit message.
