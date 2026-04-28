# Where Left Off — 2026-04-28 (M6 → M9 marathon, M10 gated)

> **Status: M0–M8 closed. M9 partially closed (code-split + Bridge stub done; real-device QA still needs hardware). M10/M11 blocked on architecture sign-off — three gates open.**

## What landed across this session (six commits, all on origin/main)

- `3a980fd` — **M6** Real OCR for Vault (Tesseract.js) + roadmap insertion of M10/M11
- `a673841` — **M7** Real AI assistant (Ollama + OpenAI-compatible) grounded in real db
- `114f8ef` — **M7.2** Streaming + action proposals + Test Connection
- `66f9702` — **M8** Real Tax forms (W-2 / 1099-NEC / 1099-INT / 1098 / 1040) + debt payoff strategy comparison
- `3a980fd → 66f9702` are M6 / M7 / M7.2 / M8 in order; the most recent commit on this branch is the M9 partial close (this session).

## Honest state

### Real (none of this is mocked)
- 15 routes, 18 Dexie tables, real CRUD on every entity.
- Backup format v3 (covers all tables incl. documents Blob via base64); v1/v2 still readable on import.
- Real CSV import for Ledger (RFC-4180 parser, dedupe, per-row review, mapping auto-detect).
- Real OCR for Vault (Tesseract.js, per-field confidence, edit-before-commit, documentId provenance).
- Real AI assistant with streaming, action proposals (zod-validated JSON blocks → confirm-or-dismiss chips → real db writes only on click), and provider health-check.
- Real Tax forms via declarative `formDefs.ts` — W-2, 1099-NEC, 1099-INT, 1098, 1040 summary. Multiple per type per year. No fake fields.
- Real debt payoff strategy comparison — avalanche vs snowball vs minimums with infeasibility detection.
- 111 unit tests, all green; typecheck clean; audit `setTimeout=5 mathRandom=0 alert=0 emptyOnClick=0`.
- Code-split bundle: main is 346 KB gzipped 107 KB (was 1.1 MB pre-split); each route 5–35 KB on demand.

### Still mocked / unbuilt
- **Auth, multi-device sync, joint households** — none of this exists. M10 + M11. Three sign-off gates still open. See `docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md`.
- **Real-device Android QA** — not possible without physical hardware. M9 leaves it open.

## Where to pick up next

### If the user signs off on the M10 architecture gates (transport / passphrase / relay)
Start M10.1 — auth scaffolding only, no UI changes yet:
1. `src/modules/auth/` — `signup`, `login`, `logout`. Argon2id passphrase → KDF. Account record + ed25519 keypair generated client-side. **Local-only — no server.**
2. `src/modules/crypto/` — wraps `crypto.subtle` AES-GCM. Round-trip test.
3. `src/modules/sync/` — Yjs document mirroring all 18 Dexie tables. Two-way bridge test (no network).
4. Tiny relay — Cloudflare Worker (~150 LOC). y-websocket transport. Server only sees ciphertext.
5. Onboarding integration — local-only path stays as default; signup is opt-in.
6. Mobile parity smoke (real device required).

### If the user wants to keep building features without M10
- **M7.2 polish:** smarter context windowing (summarize older turns when tokens are tight), streaming health-check (test with `chatStream` not just `chat`), per-conversation memory persistence.
- **M9 polish (when device available):** real-device APK smoke, safe-area pass, PWA install flow validation.
- **M5/M6/M8 carry-overs:** QFX/OFX parser, `payeeRules` Dexie table, more 1099 variants (1099-MISC, 1099-DIV, 1099-R), Mission Control cross-module rebuild.

## Build / sync state
- `npm test` — **111 passed** (verified 2026-04-28)
- `npm run typecheck` — clean
- `npm run audit:controls` — baseline `setTimeout=5 mathRandom=0 alert=0 emptyOnClick=0`
- `npm run build` — main 346 KB / gzip 107 KB; routes 5–35 KB each
- `npx cap sync` — re-verify before any real-device test

## Hard rules for the next agent

1. **Do not start M10 code without user sign-off** on transport (A cloud / B E2EE-CRDT / C peer-only — recommended B), passphrase model, and relay deployment.
2. **Do not regress audit-controls counts.** New legit UX timer? Update `tools/audit-controls.baseline.json` in the same commit and explain why.
3. **Stable IDs (`createId()` UUIDs) and per-record `personId` are load-bearing for M10 + M11.** Don't drop either.
4. **Read-only assistant remains default for non-action chat.** When the model emits a `beacon-action` block, never auto-apply — always surface as a confirm chip.
5. **Don't undo the code-split** without checking the bundle-size impact.

## Reference
- `docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md` — M10/M11 architecture + the three sign-off gates
- `docs/INTEGRATIONS_STRATEGY.md` Domain 5 — superseded for sync; other domains still authoritative
- `docs/COMPLETION_MASTER_PLAN.md` — overall narrative
- `docs/GUI_COMPLETION_CHECKLIST.md` — per-control inventory (now mostly green)
