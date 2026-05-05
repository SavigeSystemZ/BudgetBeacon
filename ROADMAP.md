# Roadmap

> **Last updated 2026-05-05.** Final Hardening pass approved (`/home/whyte/.claude/plans/ethereal-hatching-bear.md`): five sequential phases (Phase 0 truth-reset → Phase 1 APK hardening → Phase 2 GUI polish → Phase 3 M10 closeout → Phase 4 M11 → Phase 5 M12 release). M10.1–M10.4 wired in commits `1e21317` + `6637da9`; relay deploy, recovery codes, onboarding, joint household, and release docs are this pass's deliverables. Android emulator (Pixel 7 / API 34) is the accepted M9 verification surface; physical-device run is optional stretch.

## Current horizons

- **Horizon 1 (DONE): Truth, GUI, and trust.** M0–M4. Docs match reality, GUI surface honest, backup/restore/reports trustworthy.
- **Horizon 2 (DONE through M6): Real data ingestion.** M5–M7. Replace simulated Bank Sync, Scavenge, Credit Fetch, AI chatbot with real adapters or honest "manual" labels.
- **Horizon 3 (next): Deepening & polish.** M8–M9. Tax/credit/debt deepening, Android/web polish.
- **Horizon 4 (new — multi-device & multi-user): Identity + sync.** M10–M11. Auth, cross-device sync, joint household.
- **Horizon 5 (release): Distribution.** M12. Install/recovery docs, public release.

## Milestones

### M0 — Repo Truth Reset ✅ (2026-04-25)
Planning docs match runtime reality. Two new strategy docs.

### M1 — GUI Surface Audit & Completion Matrix ✅ (2026-04-25)
Per-control checklists for all 15 routes.

### M2 — Core Data + Validation Hardening ✅ (2026-04-25)
`npm test`, vitest harness, ErrorBoundary, IncomeRoute frequency drift fix, backup completeness fix.

### M3 — Full GUI Completion Pass ✅ (2026-04-25)
Every alert-only button replaced. Audit baseline `setTimeout=2 mathRandom=0 alert=0`.

### M4 — Reports, Backup, Restore, Recovery ✅ (2026-04-26)
Backup format v3 with documents. Real CSV exports. 5 report tabs. Restore-confirmation diff preview.

### M5 — Ledger + Bank/Data Import Foundation ✅ (2026-04-26)
`src/modules/import/` (parseCsv, dedupeKey, mapRows, autoDetect). 4-step import modal. `bankImportTierA = true`.

### M6 — Vault + OCR + Extraction Review ✅ (2026-04-28)
Tesseract.js browser-side OCR via `OcrProvider` interface. `VaultExtractionReview` modal with per-field confidence + edit. Apply-on-approve writes to `incomeSources` / `bills` / `taxRecords` with documentId provenance. `featureFlags.ocrLocal = true`. 71 tests passing.

### M7 — AI Assistant Real Integration ✅ (2026-04-28, substantial)
`src/modules/ai/` ships an `AiProvider` interface with two concrete providers — `OllamaProvider` (local-first default) and `OpenAiCompatibleProvider` (cloud opt-in, works with OpenAI / Groq / Together / OpenRouter / LM Studio / llama.cpp / vLLM). `providerFactory.resolveActiveProvider()` reads the existing `aiConfig` Dexie row. `contextBuilder.buildAssistantContext()` injects a real-data system prompt (income / bills / debts / subs / pressure ratios / stability index) so the model never invents numbers. `BeaconChatbot` rewritten — status badge (Local/Cloud/Not configured), abort button, error surfacing, no-provider fallback that cites real db aggregates rather than canned replies. Both `featureFlags.aiAssistantLocal` and `aiAssistantCloud` flipped to true. 16 new tests; 87 total. **Read-only this slice — tool-use / action proposals are M7.2.**

### M8 — Tax / Credit / Debt / Household Planning Deepening
- **Outcome:** Tax forms either real (proper field set + calculations) or labeled "manual draft assist." Avalanche vs snowball debt comparison. Credit snapshot UX honest about manual entry. Cross-module household planning summary.
- **Dependencies:** M7.
- **Risks:** Tax compliance accuracy — if not real, must be unambiguously labeled draft.

### M9 — Android / Web Final Polish (pre-sync) ✅ (2026-04-28 partial; emulator stand-in accepted 2026-05-05)
Code-split each route via React.lazy + Suspense — main bundle dropped 1.1 MB → 346 KB (gzip 107 KB). Beacon Bridge route copy links to Settings export/import and uses **`BACKUP_FORMAT_HELP_TEXT`** (current JSON backup format label + import notes). Automatic sync framing points at **M10/M11** and `docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md`. Sync feature flags reorganized for the new milestone owners. **Still open in M9:** real-device APK smoke + safe-area visual QA + PWA install validation — use **`docs/M9_ANDROID_QA_CHECKLIST.md`** on a physical Android (not substitutable by emulator-only for final sign-off). The route-load latency is now bounded since each route averages 10–30 KB gzipped, so sync work in M10 won't be sandbagged by an oversized initial bundle.

### M10 — Auth + Cross-Device Sync ⭐ (M10.1–M10.4 ✅; M10.5/M10.6 in Phase 3 of Final Hardening)
- **Outcome:** Account signup/login with passphrase-derived key. Same login syncs data across phone ↔ web within seconds. Server (thin relay) only sees ciphertext. Existing local-only path remains supported for users who don't sign up.
- **Architecture:** End-to-end-encrypted CRDT (Yjs) over a thin websocket relay — see `docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md`. Option B (recommended) signed off 2026-05-05.
- **Slices:** M10.1 auth scaffold ✅ → M10.2 crypto envelope ✅ → M10.3 CRDT mirror ✅ → M10.4 relay + transport ✅ → **M10.5 onboarding integration (Phase 3)** → **M10.6 emulator parity smoke (Phase 3)**. Recovery codes added in Phase 3.
- **Relay shape:** Cloudflare Worker (~150 LOC) + Durable Objects (one DO per `householdId`) + HMAC-signed join token. Optional Node.js fallback for self-hosters.
- **Risks:** Argon2id cost on low-end Android (mitigated by emulator-only verification this pass); Yjs ↔ Dexie bridge edge cases on document blobs; relay disconnect must not corrupt local data. Mitigations in the architecture doc.

### M11 — Joint Household / Linked Accounts ⭐ NEW
- **Outcome:** Two accounts can link to the same household. Both edit the same budget. CRDT auto-merges. Per-record ownership labels (Person A / Person B / Joint). Activity log shows who did what. Either side can leave with their data.
- **Slices:** M11.1 invite → M11.2 accept → M11.3 ownership UX → M11.4 activity log → M11.5 leave/unlink + key rotation → M11.6 view-only mode (stretch).
- **Dependencies:** M10 (single-account sync proven first).
- **Risks:** Invite code leakage, key-rotation correctness on leave, conflict UX. Mitigations in the architecture doc.

### M12 — Public Release / Install & Recovery Docs (Phase 5 of Final Hardening)
- **Outcome:** `docs/THREAT_MODEL.md`, `docs/INSTALL.md`, `docs/RECOVERY.md` shipped. Release checklist in `RELEASE_NOTES.md` passes (validate green, audit:controls baseline, signed APK uploaded, relay reachable, two-emulator parity green, threat model reviewed). Tag `v1.0.0` triggers `android-release.yml` to publish a signed sideload APK + `mappings.txt` + checksums to the GitHub Release.
- **Distribution shape:** Sideload APK only (Play Store / AAB explicitly out of scope this pass).
- **Dependencies:** M11.

## Cross-cutting themes

- **Honesty over breadth.** Removing or feature-flagging a fake surface still counts as progress.
- **Backup safety first.** No destructive testing without verified backup round-trip.
- **Local-first default.** Cloud features (AI, sync, aggregator) are opt-in and clearly labeled. Sync uses a relay we control with end-to-end encryption — server can never read household data.
- **Stable IDs across devices.** All `createId()` UUIDs are device-agnostic; M10 CRDT merge depends on this and it's already the pattern.

## Notes

- Active execution detail lives in `PLAN.md`.
- Per-control completion scoring lives in `docs/GUI_COMPLETION_MAP.md`.
- Integration-specific phasing lives in `docs/INTEGRATIONS_STRATEGY.md` (Domains 1–4 still authoritative; Domain 5 superseded by `docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md`).
- Master narrative plan lives in `docs/COMPLETION_MASTER_PLAN.md`.
- Sync + dual-account architecture lives in `docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md`.
