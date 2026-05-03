# Ungated Product Backlog (continuous enhancement)

Budget Beacon milestone **M10 (sync)** and **M11 (joint households)** stay **explicitly gated** on architecture sign-off per `docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md` and `PLAN.md`.

Until those gates lift, high-value engineering can advance on **local-first** UX, correctness, polish, packaging, and trust — without implying sync exists.

---

## Tier A — Highest leverage (trust + daily use)

1. **Physical Android QA (M9 remainder)** — follow **`docs/M9_ANDROID_QA_CHECKLIST.md`**: safe-area, ledger import on device, OCR memory on mid-range CPUs, offline PWA after kill/relaunch.
2. **Backup/export regression coverage** — expand Vitest beyond round-trip primitives: Blob round-trip edge cases for Vault, malformed v1 backup smoke.
3. **Assistant grounding audits** — when adding Dexie tables, follow **`docs/ASSISTANT_CONTEXT_COVERAGE.md`** + extend `collectAssistantPromptFacts` (prefer counts/aggregates). Optional: widen `audit:controls` or a small codegen check against `fullDatabaseRwScope()` vs context loader.

## Tier B — Depth & cohesion

4. **Tax Taxi** — form validation surfaced as field-level messages; optional CSV export per saved form snapshot.
5. **Debt simulator** — “what-if” extra payment sliders fed into existing payoffSimulator with chart annotation.
6. **Mission Control + Reports narrative** — one shared formatter for MTD rollup lines (Dashboard / Reports / Mission / placeholder reply) keyed off the same rollup builder output.

## Tier C — Platform & ergonomics

7. **Electron** — tighten `electron/main.cjs` single-instance + deep-link plan for backups (manual file picker parity with web Capacitor).
8. **Keyboard & focus** — focus trap optional for stacked `BeaconModal`s; RovingTabIndex where card grids act as toolbars.
9. **International readiness** — centralize currency/number/date format prefs (stored in `preferences` + Dexie mirrors) ahead of localization.

## Tier D — Housekeeping automation

10. **`npm run validate` in CI** — if Actions exist, mirror `lint && typecheck && test && build` on PRs targeting `main`.
11. **`audit:controls`** — run whenever adding `setTimeout` / RNG / `alert` in UI flows; baseline lives in `tools/audit-controls.baseline.json`.

---

## Expansion planning (sync era — after gates)

When M10 is approved, execute in order documented in **`docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md`**: Auth → crypto envelope → Yjs CRDT Dexie mirror → relay → onboarding path. Joint household UI follows M11 gates.

Maintain **dual-path honesty**: anonymous local-first mode never requires an account.

---

_Last reviewed: 2026-05-03. Update when TODO/WHERE_LEFT_OFF arcs change materially._
