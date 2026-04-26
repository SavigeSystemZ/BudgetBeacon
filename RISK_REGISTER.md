# Risk Register

> **Truth Reset — 2026-04-25.** Prior register held generic AIAST template entries. The risks below are concrete to Budget Beacon's current state, with file:line evidence in `FIXME.md` and `docs/GUI_COMPLETION_MAP.md`.

Use this file for active delivery, quality, security, release, and operational risk.

## Entry format

- Risk:
- Severity:
- Area:
- Why it matters:
- Mitigation:
- Trigger to revisit:
- Owner:

## Active risks

### ~~R1 — Trust gap from mocked surfaces~~ — substantially mitigated by M3 (2026-04-25)
- M3.1 + M3.2 removed every mocked write-to-db path: Vault Scavenge + Commit-to-App, Ledger Bank Sync + Scavenge + Commit-All, Credit Bank Fetch + Credit Check, Beacon Bridge Scan + Merge. Insurance Inspect rewritten as real manual CRUD. Chatbot now labeled Demo. Audit-controls baseline `setTimeout=2 mathRandom=0 alert=0`.
- **Residual risk:** the chatbot still produces text replies (clearly labeled placeholders). The M9 Bridge route does not yet do real device sync (clearly labeled). Document OCR is gone but not yet replaced (M6).
- **Re-trigger:** if any new mocked-write surface ships, or if `audit:controls` baseline grows.

### ~~R2 — No automated test lane~~ — resolved M2
- M0 audit was wrong about "no test files" (17 already existed). M2 added the missing `test`/`typecheck`/`audit:controls` scripts and a backup round-trip suite. Total 22 tests, 3 files. Re-trigger if test count drops or any module ships without tests.

### R3 — Backup completeness (was: format unversioned)
- **Severity:** Medium → Resolved M2; downgraded to a watch item.
- **Area:** Data recovery
- **What was actually wrong:** `exportDatabaseToJson` already had `version: 1` (M0 risk wording was imprecise). The real bug, found in M2: backup only included 8 of 18 db tables, silently wiping the other 9 on import. Fixed in M2 — bumped to v2 covering all 17 JSON-serializable tables; v1 backups still validate. `documents` (Blob) intentionally still excluded.
- **Remaining work (M4):** add base64 round-trip for `documents`; add diff-preview-before-commit on import; consider passphrase-encrypted backup (Phase 3 per `docs/INTEGRATIONS_STRATEGY.md`).
- **Trigger to revisit:** Before any Dexie schema change beyond v4; before M4 ships.

### ~~R4 — No error boundaries~~ — resolved M2
- Added root + per-route `ErrorBoundary` in `src/App.tsx`. Re-trigger if any new top-level provider is introduced that wraps the boundary (provider errors would still blank the app).

### R5 — Settings persistence missing
- **Severity:** Medium
- **Area:** Configuration / forward compatibility
- **Why it matters:** UI toggles and AI Config form (`SettingsRoute.tsx:168-209, 241-266`) don't persist. Once M7 wires real AI providers, lost-on-reload config will block real use.
- **Mitigation:** M3 wires Settings to db (`aiConfig` table for AI; new `preferences` table or localStorage for toggles).
- **Trigger to revisit:** End of M3.
- **Owner:** current maintainer

### R6 — Documentation drift recurrence
- **Severity:** Medium
- **Area:** Process / planning
- **Why it matters:** Prior docs claimed "Mission Ready / fully delivered" while runtime mocks remained. Recurrence would erase the gains of M0.
- **Mitigation:** Hard rule in `WHERE_LEFT_OFF.md`: no completion claim without runtime evidence. M0 documents reference file:line for every claim.
- **Trigger to revisit:** Each milestone close. Reject completion claims without runtime evidence.
- **Owner:** current maintainer

### R7 — Capacitor / Android version drift
- **Severity:** Medium
- **Area:** Packaging
- **Why it matters:** Capacitor and Android Gradle versions can shift between dev refresh and release; APK could break unexpectedly.
- **Mitigation:** Pin Capacitor + Android Gradle versions; smoke test APK at every milestone close.
- **Trigger to revisit:** Before M9 release candidate.
- **Owner:** current maintainer

### R8 — Privacy / cloud-AI exposure
- **Severity:** High (when M7 lands)
- **Area:** Security / privacy
- **Why it matters:** When M7 introduces optional cloud AI providers, financial transaction data could leak to third-party APIs if defaults are wrong.
- **Mitigation:** Local-only default; cloud provider is explicit opt-in with a UI warning. Never send raw transactions; redact payee/amount unless user explicitly enables.
- **Trigger to revisit:** Before M7 ships.
- **Owner:** current maintainer

### R9 — OCR commit without review (M6 risk)
- **Severity:** High (when M6 lands)
- **Area:** Data integrity
- **Why it matters:** Current `applyScavengedData` writes mock-extracted data on one click. If real OCR replaces the mock without inserting a review step, low-confidence extractions will silently corrupt records.
- **Mitigation:** M6 must include a review-before-commit UI with per-field confidence display. No auto-commit path.
- **Trigger to revisit:** M6 design review.
- **Owner:** current maintainer

### R10 — Aggregator (Plaid/MX/Finicity) commitment risk
- **Severity:** Medium (when M5 considers Tier B)
- **Area:** Vendor lock-in / cost
- **Why it matters:** Bank-aggregator providers have ongoing cost and contractual minimums. Committing in M5 before CSV/OFX path is solid risks unnecessary lock-in.
- **Mitigation:** M5 ships Tier A (CSV/QFX/OFX) only. Tier B (aggregator) remains design-only behind a disabled flag until household actually needs it.
- **Trigger to revisit:** When CSV/OFX import is in real use and proven insufficient.
- **Owner:** current maintainer

## Watch list

- **Documents-table backup gap** — `documents` (Blob storage) is excluded from JSON backup; users who only have a JSON backup will lose uploaded files on restore. M4 adds base64 round-trip. Until then, recommend a separate file-system snapshot of the IndexedDB before destructive operations.
- **Mock-control regression** — `npm run audit:controls` baseline at M2 close is `setTimeout=10, Math.random=2, alert=15, emptyOnClick=0`. Any increase fails local check. Run after every M3 batch.
- **No retry / offline graceful-degradation** — Becomes relevant when M5/M7 introduce network calls. Plan offline-tolerance now.
- **Inflated demo data** — `va-assistance-seed.json` values noted as needing verification (see TODO).

## Resolved (kept for trail)

- **Doc drift across PLAN/ROADMAP/WHERE_LEFT_OFF/TODO/FIXME** — Resolved by M0 truth reset, 2026-04-25.
- **R2 No automated test lane** — Resolved by M2, 2026-04-25 (tests + scripts in place, 22 passing).
- **R3 Backup completeness** — Resolved by M2 (v2 format covers all 17 JSON-serializable tables; documents/Blob deferred to M4 — see Watch list).
- **R4 No error boundaries** — Resolved by M2 (root + per-route).
- **Income biweekly factor approximation** — Resolved by M2 (was a duplicate display calc in IncomeRoute, not the engine; replaced with shared helper).

## Usage rules

- Keep this focused on real risk, not generic worry.
- Cross-link material unresolved issues from `FIXME.md`.
- Every active risk should have a "Trigger to revisit" so it does not silently linger.
