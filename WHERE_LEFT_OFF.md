# Where Left Off — 2026-04-28

> **Status: M6 closed.** All currently-queued data-ingestion milestones (M0–M6) are honest, tested, and committed. Two new milestones (M10 Auth+Sync, M11 Joint Household) inserted into the roadmap per user request — see `docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md`. Architecture decision needs user sign-off before M10.1 starts.

## What just happened (this session)

- **Closed M6 — Vault + OCR + Extraction Review.** Working tree had the implementation in flight; this session validated, fixed audit-controls baseline drift, and committed.
  - **`src/modules/ocr/`** — `OcrProvider` interface (`types.ts`), `tesseractProvider.ts` (Tesseract.js wrapper, browser-side, no network), `extractFields.ts` (regex extraction of date/amount/payee/label from raw OCR text), `applyExtraction.ts` (commits `ExtractedField[]` → `incomeSources` / `bills` / `taxRecords` with `documentId` provenance).
  - **`src/components/vault/VaultExtractionReview.tsx`** — modal with raw OCR text panel + per-field editor + confidence badges. No auto-commit.
  - **`src/routes/DocumentStoreRoute.tsx`** — Scavenge button on each document card runs the extraction; review modal handles approve.
  - **`featureFlags.ocrLocal`** flipped to `true`.
  - **Tests:** 9 new cases in `extraction.test.ts` and `extractFields.test.ts` covering field extraction, applyExtractionToDb routing (paystub → income, bill → bill), provenance pointer in notes, and feature-flag wiring. **Total 71 passing (was 59).**
  - **Audit baseline updated** to `setTimeout=5 mathRandom=0 alert=0 emptyOnClick=0`. The 5th setTimeout is `OnboardingWizard.tsx:85` (legit auto-dismiss after wizard completion); not new in M6 but caught now.
  - **Validation:** `npm test` 71 passed; `npm run typecheck` clean; `npm run audit:controls` no regressions; `npm run build` clean (PWA generated).
- **Inserted M10 + M11 into the roadmap.** New `docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md` covers identity model, three transport options (cloud / E2EE-CRDT / peer), a recommendation (E2EE CRDT via Yjs over a thin relay), and slice-level breakdown for both new milestones. `ROADMAP.md` updated; `INTEGRATIONS_STRATEGY.md` Domain 5 marked as superseded for sync. Renumbered the old M9 release-candidate work into a new M12 to keep release as the last step.
- **`tsx` added as a devDep** so `npm run audit:controls` works again on this host.

## Honest state of the app

### Real
- 15 routes. Dexie v4 with 18 tables. Real CRUD on every primary entity.
- Backup format v3 (covers all tables including documents Blob via base64). v1/v2 still readable.
- Real CSV export per entity + JSON full backup. Restore with diff preview.
- Real CSV import for Ledger (RFC-4180 parser, dedupe, per-row review, mapping auto-detect).
- Real OCR for Vault (Tesseract.js browser-side, per-field confidence, edit-before-commit, documentId provenance on every committed record).
- 71 unit tests across budget engine, stash-map calc, frequency normalization, base64 codec, csv writer, csv parser, dedupe key, row mapper, partition-by-dedupe, stability index, backup round-trip, OCR field extraction, applyExtractionToDb routing.
- Error boundaries (root + per-route).
- Audit-controls regression tool (`tools/audit-controls.ts`).

### Still mocked / unbuilt
- **Beacon chatbot** — `setTimeout` + canned replies. M7 owns.
- **Beacon Bridge route** — old single-button "sync to partner's phone" mock. Will be rebuilt in M10/M11; in the meantime it's gated and labeled.
- **Credit Bank Fetch / Free Credit Check** — `Math.random` mocks were removed in M3; the surface is now manual entry only. No real bureau integration is realistically possible.
- **Insurance Inspect** — rewritten in M3 as honest manual CRUD. No third-party quote API.
- **Tax Taxi forms** — still 2-field placeholder; M8 deepens or labels.
- **Auth, identity, multi-device sync, joint households** — none of this exists yet. M10 + M11 own it.

## Where to pick up next

**Two parallel paths the next agent can pick up:**

### Path A — Continue the original sequence (M7 → M8 → M9 → M10 → M11 → M12)
This is the "finish the household app for one user, then add multi-user" path. Lower risk; no architecture re-keying mid-flight.

- **M7 first:** Replace mocked chatbot in `BeaconChatbot.tsx:44-62`. Provider abstraction (`AiProvider` interface). Local Ollama / OpenAI-compatible endpoint as the first concrete provider. Persist `aiConfig` (already wired in M3 — just consume). Action proposals must require explicit user confirmation; no silent db writes.
- Reference: `docs/INTEGRATIONS_STRATEGY.md` Domain 4.

### Path B — Skip ahead to M10 (sync) once architecture is signed off
Only do this if the user signs off on the architecture in `docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md`. Concretely needed:

1. User confirms transport option **B (E2EE CRDT + thin relay)** vs A (cloud-backed) vs C (peer-only). Default recommendation is B.
2. User accepts the passphrase + recovery-code model.
3. User green-lights spinning up a small relay (Cloudflare Worker or tiny VPS, $0–5/mo).

If those three are in hand, M10.1 (auth scaffolding) is the first commit. Stay strictly in `src/modules/auth/` and `src/modules/crypto/` for that slice — no UI changes yet.

## Build / sync state
- `npm test` — **71 passed** (verified 2026-04-28)
- `npm run typecheck` — clean
- `npm run audit:controls` — baseline `setTimeout=5 mathRandom=0 alert=0 emptyOnClick=0`
- `npm run build` — clean (1.1 MB main bundle; chunk-splitting deferred — see TODO)
- `npx cap sync` — re-verify before any real-device test
- Database: Dexie v4 active; backup format v3

## Files changed this session
- `src/lib/flags/featureFlags.ts` — `ocrLocal: true`
- `src/routes/DocumentStoreRoute.tsx` — wired Scavenge → tesseractProvider → review → applyExtractionToDb
- `src/routes/TaxTaxiRoute.tsx` — minor lint suppression on the schema variable (unused for now, kept for M8)
- `src/components/vault/VaultExtractionReview.tsx` — NEW
- `src/modules/ocr/types.ts` — NEW (OcrProvider interface)
- `src/modules/ocr/tesseractProvider.ts` — NEW
- `src/modules/ocr/extractFields.ts` — NEW
- `src/modules/ocr/extractFields.test.ts` — NEW
- `src/modules/ocr/applyExtraction.ts` — NEW
- `src/modules/ocr/extraction.test.ts` — NEW
- `tools/audit-controls.baseline.json` — bumped setTimeout 4→5 (legit OnboardingWizard timer)
- `package.json` / `package-lock.json` — added `tsx` devDep
- `docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md` — NEW (M10 + M11 architecture)
- `ROADMAP.md` — added M10 + M11; renumbered release as M12
- `TODO.md` — M6 closed; M10 + M11 queues added
- `PLAN.md` — refreshed for current execution slice
- `CHANGELOG.md` — Unreleased section updated

## Hard rules for the next agent

1. **Do not start M10 code without user sign-off** on transport option (A/B/C) and the passphrase model. The architecture doc explicitly calls this out as a gate.
2. **Do not regress audit-controls counts.** If a new legit UX timer is added, update `tools/audit-controls.baseline.json` in the same commit and explain why in the message.
3. **Do not silently delete the Beacon Bridge route.** It's referenced from the nav. Either rebuild it against the new sync transport in M10 or replace it with an honest "Sync coming in M10" panel.
4. **Per-record `personId` is load-bearing for M11 joint households.** Don't drop it from any existing schema.
5. **Stable IDs (`createId()` UUIDs) are load-bearing for M10 CRDT merge.** Don't switch to autoincrement IDs anywhere.
