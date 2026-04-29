# Plan

> **Truth Reset — 2026-04-25.** The previous version of this file claimed Budget Beacon was "fully delivered." A repo audit performed against `src/routes/`, `src/components/BeaconChatbot.tsx`, `src/db/`, and `package.json` showed multiple advanced features still simulated and several documentation surfaces overstating completion. This plan replaces the prior text with grounded current state and a phased completion roadmap. See `docs/COMPLETION_MASTER_PLAN.md`, `docs/GUI_COMPLETION_MAP.md`, and `docs/INTEGRATIONS_STRATEGY.md`.

## Objective

- **Current target outcome:** Convert Budget Beacon from broad-prototype state into a trustworthy daily-use household budgeting app for two adults — web, Android, and (optional) Electron desktop.
- **Why it matters now:** The runtime is real and the GUI surface is broad, but several primary action buttons either alert-only, operate on hardcoded fake data, or simulate integrations with `setTimeout`. The app is not safe to call "finished" until those surfaces are honest, and the canonical planning docs match runtime reality.
- **Forcing function:** Daily household use by the maintainer and partner; the longer mocked surfaces remain misrepresented, the higher the risk of acting on fabricated numbers.

## Success criteria

- **User outcome:** Every visible primary control either does real work or is feature-flagged off / explicitly labeled "manual" or "coming later." No silent mocks.
- **Technical outcome:** Repo docs match runtime reality. Validation lane has a real `npm test` script and route-level smoke coverage. Backup/restore round-trips cleanly.
- **Product-quality outcome:** Every major route reaches Level 3 (polished) and the seven critical routes (Dashboard, Ledger, Pay Path, Stash Map, Reports, Settings, Vault) reach Level 4 (production-ready), per `docs/COMPLETION_MASTER_PLAN.md` §11.

## Scope lock

- **In scope (this milestone, M0):** Documentation truth-reset only. Rewrite `PLAN.md`, `ROADMAP.md`, `WHERE_LEFT_OFF.md`, `TODO.md`, `FIXME.md`, `RISK_REGISTER.md`. Create `docs/GUI_COMPLETION_MAP.md` and `docs/INTEGRATIONS_STRATEGY.md`.
- **Out of scope (M0):** Code changes. No feature implementation, no refactors, no removal of mocked surfaces yet — they are documented but left in place pending M1+ decisions.
- **Dependencies:** None. M0 is doc-only and has no runtime preconditions.

## Assumptions

- The audit performed on 2026-04-25 (recorded in `docs/GUI_COMPLETION_MAP.md`) is current as of this commit. If routes are edited before M1 begins, re-run the audit.
- Maintainer wants honesty over momentum: shipping a real, smaller surface beats shipping a broader simulated one.
- React/Vite/TypeScript/Dexie/Capacitor/Electron stack is the durable target; no platform reshuffles planned.

## Execution slices (M0 — Repo Truth Reset)

1. Rewrite `PLAN.md` (this file) to reflect grounded state and phased plan.
2. Rewrite `ROADMAP.md` to reflect M0–M9 sequencing.
3. Rewrite `WHERE_LEFT_OFF.md` as an honest handoff packet.
4. Rewrite `TODO.md`: uncheck inflated milestones, populate with real work.
5. Rewrite `FIXME.md` with itemized mocks, dead controls, and missing infrastructure.
6. Rewrite `RISK_REGISTER.md` with concrete delivery risks (trust gap, mock surfaces, no test script, no error boundaries, no settings persistence).
7. Create `docs/GUI_COMPLETION_MAP.md` with route-by-route classification + file:line evidence.
8. Create `docs/INTEGRATIONS_STRATEGY.md` with phased real-integration plan.

## Active execution slice (post-M9-partial, 2026-04-28)

M0–M8 closed. M9 partially closed (code-split + Bridge stub done; real-device QA needs hardware).

- **M10 — Auth + Cross-Device Sync.** **Gated on user sign-off** (transport A/B/C + passphrase model + relay green-light). See `docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md`. Halt point until user confirms.
- **M11 — Joint household.** Depends on M10.
- **M12 — Public release.**

Parallel small slices any session can take while M10 is gated:
- **M9 device QA** — real-device APK smoke + safe-area visual pass (needs physical Android).
- **M7.2 polish** — streaming health-check, smarter context windowing.
- **M5 / M8 carry-overs** — ✅ done (OFX/QFX parser, payeeRules table, 4 more 1099 variants — see CHANGELOG).

## Forward milestone sequence (M1–M12 summary)

Full detail in `docs/COMPLETION_MASTER_PLAN.md` §10. Brief:

- **M1 — GUI Surface Audit & Completion Matrix.** Already partly delivered as `docs/GUI_COMPLETION_MAP.md` in M0; M1 deepens it into per-control checklists.
- **M2 — Core Data + Validation Hardening.** Add `npm test` script. Wire Vitest. Cover budget engine, frequency normalization (income), CSV parsing, JSON import schema validation. Tighten Zod schemas at all CRUD boundaries.
- **M3 — Full GUI Completion Pass.** Replace every alert-only button with real action or feature-flag. Add loading/empty/error states everywhere. Mobile/Android safe-area pass.
- **M4 — Reports, Backup, Restore, Recovery.** Real CSV/JSON export, real PDF (or at minimum print-to-PDF with proper layout), restore confirmation flow, versioned backup format.
- **M5 — Ledger + Bank/Data Import Foundation.** Replace mocked Bank Sync with CSV/QFX/OFX import + dedupe + review queue. Hide aggregator path behind feature flag until provider is chosen.
- **M6 — Vault + OCR + Extraction Review.** Replace mocked Scavenge with real OCR (Tesseract.js browser-side) + extraction-review queue + commit-on-approve.
- **M7 — AI Assistant Real Integration.** Provider abstraction (local Ollama first, cloud second). No silent writes. Persist `aiConfig`.
- **M8 — Tax/Credit/Debt/Household Planning Deepening.** Real tax form fields (or honest "manual draft" labeling). Avalanche vs snowball debt strategy. Honest credit-snapshot UX (no fake fetch).
- **M9 — Android/Web Final Polish (pre-sync).** Safe-area QA, real-device APK smoke, Capacitor version pin. Beacon Bridge route stubbed with "coming in M10."
- **M10 — Auth + Cross-Device Sync.** End-to-end-encrypted CRDT (Yjs) over a thin relay. Account login syncs across phone ↔ web. Server only sees ciphertext. Architecture in `docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md`.
- **M11 — Joint Household / Linked Accounts.** Two accounts → one household. CRDT auto-merge. Per-record ownership labels and activity log. Leave/unlink with key rotation.
- **M12 — Release.** Install/recovery docs, threat-model doc, release checklist (incl. sync interruption + joint-leave tests).

## Validation plan (M0)

- **Commands to run:** None — this milestone is doc-only.
- **Evidence to capture:** Diffs of all six rewritten planning files plus the two new strategy docs. Confirm no claim in any planning file says "fully delivered," "Mission Ready," or "Risks: None active."
- **Stop conditions:** If audit findings change before commit (i.e., maintainer edits a mocked route between audit and commit), re-run the route audit before completing M0.

## Validation plan (forward, M1+)

- Add `"test": "vitest run"` and `"typecheck": "tsc -b --noEmit"` to `package.json` scripts (M2).
- Each milestone closes with: typecheck clean, test suite green, and a route-by-route smoke pass against `docs/GUI_COMPLETION_MAP.md`.
- Backup round-trip test (export → wipe → import → verify equality) is part of M4 done-criteria and re-run before any release.
