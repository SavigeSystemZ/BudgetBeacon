# Where Left Off — 2026-04-28 (end-of-day handoff)

> **Status: M0–M8 closed. M9 partially closed (code-split + Bridge stub; device QA needs hardware). M5/M8 carry-overs all done. M10/M11 blocked on three architecture sign-off gates. Working tree clean; `origin/main` at `dca6e70`.**

## Session arc (2026-04-28)

Six commits landed today, all on `origin/main`:

| Commit | Slice | Headline |
|---|---|---|
| `3a980fd` | **M6** | Real Tesseract.js OCR for the Vault + roadmap inserts M10/M11 + new `docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md` |
| `a673841` | **M7** | Real AI assistant: Ollama + OpenAI-compatible providers, grounded in real db via `contextBuilder` |
| `114f8ef` | **M7.2** | Streaming responses, Zod-validated action proposals with confirm chips, "Test Connection" health-check |
| `66f9702` | **M8** | Real Tax Taxi forms (W-2, 1099-NEC, 1099-INT, 1098, 1040) + debt payoff strategy comparison |
| `7b3a9b4` | **M9 partial** | Route-level code-split (1.1 MB → 346 KB main; gzip 107 KB) + Beacon Bridge re-pointed at M10/M11 |
| `dca6e70` | **M5/M8 carry-overs** | OFX/QFX parser, `payeeRules` Dexie table (v5) with auto-categorize on import, 4 more 1099 variants (MISC/DIV/R/G), backup format v4 |

## Honest state of the app

### Real (no mocks remaining in these areas)
- 15 routes, Dexie v5 with 19 tables, real CRUD on every entity.
- Backup format **v4** (covers all tables incl. documents Blob via base64 and payeeRules); v1/v2/v3 still readable on import.
- Real CSV import for Ledger (RFC-4180 parser, dedupe, per-row review, mapping auto-detect).
- Real OFX/QFX import for Ledger (skips column-mapping; bank + credit-card statements).
- Real OCR for Vault (Tesseract.js, per-field confidence, edit-before-commit, documentId provenance).
- Real AI assistant — streaming, Zod-validated action proposals (confirm chips → real db writes only on click), provider health-check.
- Real tax form library — W-2, 1099-NEC, 1099-INT, 1099-MISC, 1099-DIV, 1099-R, 1099-G, 1098, 1040 summary.
- Real debt payoff strategy comparison — avalanche vs snowball vs minimums with infeasibility detection.
- Real payee rules — user-managed merchant normalization auto-applied during all imports.
- 134 unit tests passing; typecheck clean; audit `setTimeout=5 mathRandom=0 alert=0 emptyOnClick=0`.
- Code-split bundle: main 346 KB / gzip 107 KB; each route 5–35 KB on demand.

### Still mocked / unbuilt
- **Auth, multi-device sync, joint households** — none of this exists. M10 + M11. Three sign-off gates open.
- **Real-device Android QA** — needs a physical Android.

## Where to pick up next

### A. If user signs off on M10 gates (transport / passphrase / relay)
Start M10.1 — auth scaffolding only, no UI changes yet:
1. `src/modules/auth/` — `signup`, `login`, `logout`. Argon2id passphrase → KDF. Account record + ed25519 keypair generated client-side. **Local-only — no server yet.**
2. `src/modules/crypto/` — wraps `crypto.subtle` AES-GCM. Round-trip test.
3. `src/modules/sync/` — Yjs document mirroring all 19 Dexie tables. Two-way bridge test (no network).
4. Tiny relay — Cloudflare Worker (~150 LOC). y-websocket transport. Server only sees ciphertext.
5. Onboarding integration — local-only path stays as default; signup is opt-in.
6. Mobile parity smoke (real device required).

### B. Without M10 sign-off, parallel slices
- **M7.2 polish** — smarter context windowing (summarize older turns when token budget tight), streaming health-check button using `chatStream`, per-conversation memory persistence.
- **M9 device QA** (when device available) — real-device APK smoke, safe-area pass, PWA install flow validation.
- **Mission Control rebuild** — cross-module summary card combining budget summary + stability index + debt payoff trajectory + savings ETA.
- **Accessibility audit** — color contrast, focus order, aria-labels on icon-only buttons, keyboard nav.
- **Insurance / subscriptions polish** — both routes are real CRUD but could surface upcoming-renewal alerts (uses existing `subscriptions.nextRenewal` and `insuranceRecords.expirationDate`).

## Build / sync state
- `npm test` — **134 passed** (verified 2026-04-28 end of day)
- `npm run typecheck` — clean
- `npm run audit:controls` — baseline `setTimeout=5 mathRandom=0 alert=0 emptyOnClick=0`
- `npm run build` — main 346 KB / gzip 107 KB; route chunks 5–35 KB
- `npx cap sync` — re-verify before any real-device test
- `git status` — clean; `origin/main = HEAD = dca6e70`

## Hard rules for the next agent
1. **Do not start M10 code without user sign-off** on transport (A/B/C — recommended B), passphrase + recovery-code model, and relay deployment green-light.
2. **Do not regress audit-controls counts.** New legit UX timer? Update `tools/audit-controls.baseline.json` in the same commit and explain why.
3. **Stable IDs (`createId()` UUIDs) and per-record `personId` are load-bearing for M10 + M11.** Don't drop either.
4. **Read-only assistant remains default for non-action chat.** When the model emits a `beacon-action` block, never auto-apply — always surface as a confirm chip.
5. **Don't undo the code-split** without checking the bundle-size impact.
6. **Backup format v4** — adding new tables means bumping the version, adding to `exportJson.ts`, schema in `importJson.ts`, clear+bulkAdd in the transaction, and counts in `backupRowCounts` + `currentDbRowCounts`. Test the round-trip.

## Reference
- `docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md` — M10/M11 architecture + the three sign-off gates
- `docs/INTEGRATIONS_STRATEGY.md` Domain 5 — superseded for sync; other domains still authoritative
- `docs/COMPLETION_MASTER_PLAN.md` — overall narrative
- `docs/GUI_COMPLETION_CHECKLIST.md` — per-control inventory (mostly green)
- `CHANGELOG.md` Unreleased section — full per-milestone changelog for this session
