# TODO

> **Truth Reset — 2026-04-25.** Previous TODO marked M3–M8 complete. Audit on 2026-04-25 showed multiple of those surfaces still simulated. Inflated `[x]` items have been moved to "Previously claimed complete (needs re-verification)" below. Real work queue follows.

This is the active execution queue. Keep it tight, factual, and ordered.
Use priority signals: **CRITICAL**, **HIGH**, **MEDIUM**, **LOW**.

## Current Priority

- [x] **CRITICAL: M0 — Repo Truth Reset.** Rewrite `PLAN.md`, `ROADMAP.md`, `WHERE_LEFT_OFF.md`, `TODO.md`, `FIXME.md`, `RISK_REGISTER.md`. Create `docs/GUI_COMPLETION_MAP.md` and `docs/INTEGRATIONS_STRATEGY.md`. *(Completed 2026-04-25.)*
- [x] **CRITICAL: M1 — GUI Surface Audit & Completion Matrix.** Created `docs/GUI_COMPLETION_CHECKLIST.md` with per-control inventory (~140 buttons + ~80 form fields), component-reuse map, empty/loading/error state matrix, mobile/Android parity matrix, and ordered M3 must-fix list. *(Completed 2026-04-25.)*
- [x] **CRITICAL: M2 — Core Data + Validation Hardening.** Added test/typecheck/audit-controls scripts, vitest config, ErrorBoundary, IncomeRoute frequency drift fix, backup completeness fix (v2 format covers all 17 JSON-serializable tables; documents/Blob deferred to M4), backup round-trip test. 22 tests passing, typecheck clean. *(Completed 2026-04-25.)*
- [x] **CRITICAL: M3 (substantial) — Full GUI Completion Pass.** Two commits (`72c86c3` + `ae1bbb5`). All 10 highest-priority must-fix items done. Audit counts: `setTimeout` 10→2 (legit UX), `mathRandom` 2→0, `alert` 15→0. New shared primitives: `featureFlags` map, `DemoBadge` component, `preferences` localStorage layer, `stabilityIndex` module + 7 tests. 29 tests passing. Insurance Inspect now real manual CRUD; Settings now persists toggles + aiConfig. *(Completed 2026-04-25.)*
- [x] **CRITICAL: M4 — Reports, Backup, Restore, Recovery.** Backup format v3 (documents via base64, chunked encode). Real CSV/JSON exports + 5 per-report tabs. Restore diff preview. Print stylesheet pass. 39 tests passing (10 new). Audit baseline locked at `setTimeout=4 mathRandom=0 alert=0`. *(Completed 2026-04-26.)*
- [x] **CRITICAL: M5 (substantial) — Ledger + Bank/Data Import.** New `src/modules/import/` (parseCsv, dedupeKey, mapRows, autoDetect). New `LedgerImportFlow` component: file → mapping → review → commit, with auto-detect, per-row inclusion checkbox, and "possible duplicate" highlighting. `featureFlags.bankImportTierA` flipped to true. 59 tests passing (20 new). *(Completed 2026-04-26.)*
- [x] **M5/M8 carry-overs (2026-04-28).** OFX/QFX parser (tolerant; handles bank STMTTRN + credit-card CCSTMTTRN). New `payeeRules` Dexie table (v5) with `applyPayeeRules` auto-applied to every CSV and OFX import; "✓ Auto-categorized N of M" banner. Settings gets a Payee Rules panel (CRUD). Tax library expanded by 4 forms: 1099-MISC, 1099-DIV, 1099-R, 1099-G. Backup format bumped to v4 (covers payeeRules); v1/v2/v3 still readable. 23 new tests; 134 total. *(Commit `dca6e70`.)*

- [x] **CRITICAL: M9 (partial, 2026-04-28).** Route-level code-split via React.lazy + Suspense — main bundle 1.1 MB → 346 KB (gzip 107 KB); each route 5–35 KB on demand. Beacon Bridge route copy repointed to M10/M11 with link to architecture doc. Sync feature flags reorganized (new `syncE2eeCrdt`, `jointHouseholds`). Real-device APK smoke + safe-area visual + PWA install validation still open — need physical Android. *(Commit `7b3a9b4`.)*

- [x] **CRITICAL: M8 (2026-04-28).** Real Tax Taxi forms — W-2, 1099-NEC, 1099-INT, 1098, 1040 summary via declarative `formDefs.ts`; replaces 2-field placeholder; multiple per type per year via `createId()`; saved-forms list with delete + open-to-edit. Debt payoff strategy comparison — pure simulator (avalanche/snowball/minimums) with infeasibility detection; interactive UI in Debt Center showing months-to-payoff, total interest, savings vs minimums. 8 new simulator tests; 111 total then. *(Commit `66f9702`.)*

- [x] **CRITICAL: M7.2 (2026-04-28).** Assistant streaming (Ollama JSONL + OpenAI SSE with `[DONE]` handling); Zod-validated action proposals via `beacon-action` JSON fences → confirm/dismiss chips → real db writes on click only; provider "Test Connection" button in Settings. Bug fix: `AI_CONFIG_ID` mismatch (`"default"` vs persisted `"primary"`) silenced sync in every prior session — aligned. 16 new tests; 103 total then. *(Commit `114f8ef`.)*

- [x] **CRITICAL: M7 (substantial) — AI Assistant Real Integration.** New `src/modules/ai/` with `AiProvider` interface, `OllamaProvider` (local-first, default `http://localhost:11434/api/chat`), `OpenAiCompatibleProvider` (cloud opt-in, works with OpenAI/Groq/Together/OpenRouter/LM Studio/llama.cpp), `providerFactory.resolveActiveProvider()` reading `aiConfig`, `contextBuilder.buildAssistantContext()` building a real-data system prompt from budget summary + stability index. `BeaconChatbot.tsx` rewritten — no canned replies, status indicator (Local/Cloud/Not configured), abort button, error surfacing, honest no-provider fallback citing real db numbers. `featureFlags.aiAssistantLocal` + `aiAssistantCloud` flipped to true. 16 new tests covering URL normalization, response parsing, error wrapping, factory resolution. 87 tests total. *(Completed 2026-04-28.)*

- [x] **CRITICAL: M6 — Vault + OCR + Extraction Review.** `OcrProvider` interface in `src/modules/ocr/types.ts`; `tesseractProvider.ts` wraps Tesseract.js (browser-side, no network). `extractFields.ts` extracts date/amount/payee/label from raw OCR text via regex. `applyExtraction.ts` commits approved `ExtractedField[]` to `incomeSources` / `bills` / `taxRecords` with `documentId` provenance. `VaultExtractionReview` modal: raw text panel + per-field editor + confidence badges, no auto-commit. `featureFlags.ocrLocal = true`. 71 tests passing (12 new). Audit baseline now `setTimeout=5 mathRandom=0 alert=0`. *(Completed 2026-04-28.)*

## Immediate Queue — pick a path

**Path A (default): continue → M8 (Tax/Credit/Debt deepening) → M9 (Android polish) → M10/M11 (sync, joint household).**
**Path B: skip to M10 (Auth + Sync) — requires architecture sign-off.** See `docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md`.

### Open M7.2 polish (not blocking)

- [x] Streamed token rendering (M7.2 commit `114f8ef`).
- [x] Tool-use / structured action proposals with explicit confirmation (M7.2 commit `114f8ef`).
- [x] Provider health-check button in Settings (M7.2 commit `114f8ef`).
- [ ] **LOW:** Per-conversation context windowing — currently sends last 8 turns; consider summarizing older history when token budget is tight.
- [ ] **LOW:** Streaming health-check (Test Connection currently uses `chat`, not `chatStream`).

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

## M5 — Ledger + Bank/Data Import Foundation ✅ DONE (M5 + M5 carry-overs)

- [x] Mocked Bank Sync removed from `LedgerRoute.tsx`.
- [x] Real CSV import — file picker → parse → map → dedupe → review → commit (M5).
- [x] OFX/QFX parser shipped (M5 carry-over `dca6e70`) — bypasses column mapping.
- [x] Merchant/payee normalization rules — `payeeRules` Dexie table + Settings panel + auto-apply during all imports (M5 carry-over `dca6e70`).

## M6 — Vault + OCR + Extraction Review ✅ DONE (2026-04-28)

- [x] **HIGH:** Removed mocked Scavenge in `DocumentStoreRoute.tsx`; replaced with real Tesseract.js extraction.
- [x] **HIGH:** Tesseract.js browser-side OCR shipped via `OcrProvider` interface.
- [x] **HIGH:** Extraction-review UI: confidence per field, edit before commit, `documentId` provenance pointer in record `notes`.

## M7 — AI Assistant Real Integration (queued)

- [ ] **HIGH:** Replace mocked chatbot in `BeaconChatbot.tsx:44-62` with provider abstraction.
- [ ] **HIGH:** Local provider first (Ollama / OpenAI-compatible local endpoint).
- [ ] **MEDIUM:** Cloud provider opt-in (Anthropic / OpenAI), clearly labeled non-local.
- [ ] **HIGH:** All assistant action proposals require explicit user confirmation before db writes.

## M8 — Tax / Credit / Debt / Household Planning Deepening (queued)

- [ ] **HIGH:** Remove mocked Credit Bank Fetch + Credit Check (`CreditRoute.tsx:57-74`); keep manual snapshot UX as the honest baseline.
- [ ] **HIGH:** Avalanche vs snowball debt strategy comparison in Debt Center.
- [ ] **MEDIUM:** Cross-module household planning summary (Mission Control rebuild on real data).

## M9 — Android / Web Final Polish (pre-sync) — partially done

- [x] Beacon Bridge route repointed to M10/M11 with link to architecture doc.
- [x] Bundle code-split via React.lazy. Main 1.1 MB → 346 KB (gzip 107 KB); routes 5–35 KB each on demand.
- [ ] **HIGH (needs physical Android):** Safe-area + APK smoke on real device. Pin Capacitor / Android versions before M10 starts.
- [ ] **HIGH (needs physical Android):** PWA install flow validated.
- [ ] **MEDIUM:** Accessibility audit (color contrast, focus order, aria-labels on icon-only buttons, keyboard nav).

## M10 — Auth + Cross-Device Sync (queued — needs architecture sign-off)

> Architecture: `docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md`. Recommended option B (E2EE CRDT + thin relay via Yjs). Requires user sign-off on transport choice + passphrase model + relay deployment before M10.1.

- [ ] **CRITICAL gate:** User signs off on transport option (A cloud-backed / B E2EE-CRDT / C peer-only). Default recommendation: B.
- [ ] **CRITICAL gate:** User accepts passphrase + one-time recovery-code model.
- [ ] **CRITICAL gate:** User green-lights a tiny relay (Cloudflare Worker or small VPS, $0–5/mo).
- [ ] **M10.1:** Auth scaffold — `src/modules/auth/` with signup/login/logout. Argon2id passphrase → key derivation. Account record + keypair generated client-side. Local-only at first.
- [ ] **M10.2:** Encryption envelope — `src/modules/crypto/` wrapping `crypto.subtle` AES-GCM. Round-trip test.
- [ ] **M10.3:** CRDT mirror — Yjs document mirroring all 18 Dexie tables. Two-way sync test (no network).
- [ ] **M10.4:** Relay + transport — thin Node+ws or Cloudflare Worker relay (~150 LOC). Client connects via `y-websocket` with the household-key envelope. "Sync status" indicator in bottom nav.
- [ ] **M10.5:** Onboarding integration — existing `OnboardingWizard` learns to either continue local-only or sign up for sync. Migrate local Dexie data to the user's Household on first sync.
- [ ] **M10.6:** Mobile parity smoke — real-device APK install, log in, verify data appears.

## M11 — Joint Household / Linked Accounts (queued — depends on M10)

- [ ] **M11.1:** Invite flow — Settings → "Invite partner" generates a one-time code (24 h, single-use) wrapping an ephemeral key.
- [ ] **M11.2:** Accept flow — second account enters code, gets the household key, joins.
- [ ] **M11.3:** Per-record ownership UX — surface "owned by Person A / Person B / Joint" labels using existing `personId`. Add per-record visibility toggle (private vs shared).
- [ ] **M11.4:** Activity log — new `householdActivity` Dexie table, populated from CRDT merge events.
- [ ] **M11.5:** Leave / unlink — leaving account exports a v3 backup of their last state. Remaining account keeps the household; key rotates on leave.
- [ ] **M11.6 (stretch):** View-only mode for a second account.

## M12 — Public Release / Install & Recovery Docs (queued — final)

- [ ] **HIGH:** Install/update/recovery docs in repo.
- [ ] **HIGH:** Threat-model + privacy doc shipped alongside the build (especially for sync).
- [ ] **HIGH:** Release checklist incl. sync-interruption test and joint-household-leave test.
- [ ] **HIGH:** Replace mocked Insurance Inspect remnants if any survive (M3 already rewrote it; re-verify).

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
