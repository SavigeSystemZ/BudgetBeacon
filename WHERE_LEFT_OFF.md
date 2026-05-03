# Where Left Off — **paused 2026-05-03**

> **Session stop:** Resume from **`git log -1`** on **`main`** (this pause batch is committed locally). **`npm run validate`** was green with **164** Vitest tests; **`npm run audit:controls`** OK (**`setTimeout=5`**, **`alert=0`**). Next session: **`git pull`** / **`git push`** using the operator account **per `GIT_REMOTE_AND_SYNC_PROTOCOL.md`** when sharing; otherwise continue **`docs/UNGATED_PRODUCT_BACKLOG.md`** Tier A (e.g. **`docs/M9_ANDROID_QA_CHECKLIST.md`** on hardware). **M10/M11** (sync / joint households) stay **gated** until explicit architecture sign-off.
>
> **Status:** M0–M8 closed; M9 partial (code-split). Earlier 2026-05-02 CouplesWealth scavenger + rollups noted in sections below.

## 2026-05-03 continuation (debt trajectory downsample module)

- **`trajectoryDownsample.ts`** — pure **`downsamplePayoffTrajectory`** extracted from **`StrategyComparison`**; **`trajectoryDownsample.test.ts`** (short-series copy, long-series last point, no duplicate when stride hits last month). Terminal merge compares **`month` / `totalBalance`**, not object identity.
- **`npm run validate`** green; **164** tests; **`npm run audit:controls`** OK.

## 2026-05-03 continuation (debt what-if + Android QA checklist)

- **`StrategyComparison`:** extra-payment **presets** + **range slider** + a11y hints. **`docs/M9_ANDROID_QA_CHECKLIST.md`** for physical-device M9 remainder; backlog Tier A points here.
- **`npm run validate`** green; **161** tests.

## 2026-05-03 continuation (assistant counts + CI)

- **`collectAssistantPromptFacts`** + **`AssistantContextFacts`:** tax forms / records, vault docs, payee rules as **counts** in prompt + no-model placeholder path. **`docs/ASSISTANT_CONTEXT_COVERAGE.md`**. **`.github/workflows/ci.yml`** → **`npm run validate`**.
- **`npm run validate`** green; **161** tests.

## 2026-05-03 continuation (backlog doc + reset API)

- **`resetToBundledDemo()`** consolidates Settings demo path; **`resetToBundledDemo.test.ts`**. **`docs/UNGATED_PRODUCT_BACKLOG.md`** + links from **`PLAN.md`** / **`TODO.md`**. **`ROADMAP`** M9 wording; Bridge header a11y tweak.
- **`npm run validate`** green; **159** tests; **`audit:controls`** OK.

## 2026-05-03 continuation (wipe copy DRY)

- **`src/lib/fullDatabaseWipeCopy.ts`** feeds Dashboard + Settings wipe modal strings; wiping closes modal immediately then runs **`clearDatabase()`**. **`158`** tests; **`npm run audit:controls`** OK.

## 2026-05-03 continuation (wipe / demo Beacon modals)

- **`DashboardRoute`:** Wipe All → **`BeaconModal`** → **`clearDatabase`** + reload. **`SettingsRoute`:** same for wipe + separate modal for demo reset (**`clearDatabase`** then **`seedDemoData`** + reload — fixes prior no-op when households already existed).
- **`npm run validate`** green; **157** tests.

## 2026-05-03 continuation (modal delete confirmations)

- **`DeleteConfirmProvider`** wraps **`AppShell`** (`App.tsx`). Routes use **`useDeleteConfirm()`** instead of **`confirmEntityDelete` / `window.confirm`** for entity row deletes (**11** surfaces). **`BeaconModal`:** **`data-beacon-modal-backdrop`**, Escape → **`onClose`**. Chat FAB Escape skips when a modal backdrop exists.
- **`npm run validate`** green; **157** tests.

## 2026-05-03 continuation (chat clear + shell a11y)

- **`BeaconChatbot`:** Clear history → **`BeaconModal`** (destructive footer); floating toggle **`aria-expanded`** + **`aria-controls`**; open panel **`role="region"`** + **`aria-label`**; **`streamingText`** in scroll **`useEffect`** deps; suggestion row **`type="button"`**.
- **`App.tsx`:** Mobile menu open/close/full-menu **`aria-label`**; decorative icons **`aria-hidden`**.
- **`mode-toggle`:** Dynamic **`aria-label`** (switch to light/dark); icons **`aria-hidden`** (drops duplicate **`sr-only`**).
- **`npm run validate`** green; **157** tests.

## 2026-05-03 continuation (a11y: icon buttons)

- **Routes:** **`TaxTaxiRoute`** — Add tax year / Edit labels; **`SubscriptionsShelfRoute`** — Add subscription / Edit; **`InsuranceInspectRoute`** — Add policy / Edit; **`DocumentStoreRoute`** — header upload, View, Scavenge per doc.
- **Shared:** **`BeaconChatbot`** Stop / Send; **`BeaconModal`** close; **`PayeeRulesPanel`** delete rule.
- **`npm run validate`** green; **157** tests.

## 2026-05-03 continuation (backup copy + Pay Path / Credit polish)

- **`BACKUP_FORMAT_HELP_TEXT` / `BACKUP_FORMAT_VERSION_LABEL`** in `exportJson.ts` — Settings, Reports, Bridge show **v4** truthfully. Pay Path + Credit empty states; `exportJson.constants.test.ts`. **`npm run validate`** green, **157** tests.

## 2026-05-03 continuation (DRY Dexie scope + delete UX)

- **`src/db/fullDatabaseScope.ts`:** `fullDatabaseRwScope()` is the single list for backup `applyBackupPayload` clears and `clearDatabase()` — no parallel copy in `importJson`. `confirmEntityDelete()` + **aria-label** on trash buttons (Income, Pay Path, Debt Center, Stash, Credit, Ledger, Tax Taxi, Subscriptions, Insurance, Vault). Reports empty tabs → **`EmptyState`**.
- **`npm run validate`** green; **155** tests.

## 2026-05-03 continuation (validate + wipe)

- **`clearDatabase()`** clears all IndexedDB stores (aligned with backup import wipe); Dashboard **Wipe All** delegates to it + **`window.location.reload()`** like Settings reset.
- **`npm run validate`** runs lint, typecheck, Vitest, and production **`vite build`**.
- **Evidence:** **`npm run validate`** green; **154** tests (`src/db/clearDatabase.test.ts`).
- **M10/M11** still gated.

## 2026-05-03 continuation (ESLint hygiene)

- **Lint green:** `npm run lint` passes repo-wide after moving no-model fallback to `src/modules/ai/beaconPlaceholderReply.ts` (tests import that module); fixing `react-hooks/set-state-in-effect` / deps issues (derived onboarding in `App.tsx`, Vault review inner mount, Settings prefs initializer + scoped ESLint wrapper for AI Dexie hydrate, Tax form editor key + lazy seed); replacing `any` on several routes with `z.infer` / schema types; regex/BOM nits in import + OCR helpers; Debt Center persists `apr` + `DebtCategory` mapping consistently.
- **Validation:** `npm run lint`, `npm run typecheck`, `npm run test` → **153** passed; `bootstrap/check-working-directory-alignment.sh` + `bootstrap/check-project-target-consistency.sh` OK (existing PROJECT_PROFILE app-name warn).
- **Next:** Ungated UX polish; remote push still operator-side (SSH). M10/M11 unchanged — gates first.

## 2026-05-03 continuation (Codex)

- Added unit coverage for no-provider chatbot fallback branches (`BeaconChatbot.test.ts` now targets `beaconPlaceholderReply` in `src/modules/ai/`).
- Added M7.2 polish:
  - `src/modules/ai/conversationWindow.ts` (+ tests) to summarize older chat turns and keep recent turns verbatim when building model context in `BeaconChatbot`.
  - `src/routes/SettingsRoute.tsx` Test Connection now uses `provider.chatStream(...)` so health checks validate the same streaming path used in chat.
- Mission Control polish in `BudgetMissionControlRoute.tsx`: safe % bars, insurance line under burn rate, avalanche-aligned highest-APR debt spotlight, stale M8 payoff copy removed.
- Dashboard polish in `DashboardRoute.tsx`: Global Pressure bar segments clamped when burn > 100% income; zero-income explanatory state instead of fake surplus. `BudgetHealthScoreCard.tsx`: safe progress toward target when target fraction is zero.
- Validation run in this session:
  - `npm run test` → **153 passed**
  - `npm run typecheck` → **clean**
  - `npm run lint` → **clean** (follow-up ESLint batch)
- Git remote fetch/push remains blocked in this environment (`Permission denied (publickey)`), so changes are local-only until run from the operator shell.
- Next best step: hold M10 until explicit sign-off gates are approved; continue ungated polish (dashboard/mission UX, Vault/OCR QA) — ESLint backlog for the listed hotspots is cleared.

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
- 161 unit tests passing (see latest `npm run test`); typecheck clean; audit `setTimeout=5 mathRandom=0 alert=0 emptyOnClick=0`.
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

## Build / sync state (2026-05-02 night)
- `npm test` — **148 passed** (last run this session)
- `npm run typecheck` — clean
- `npm run build` — clean (PWA may refresh `dev-dist/sw.js` / `dist/sw.js`)
- `npm run lint` — **not** repo-wide clean; legacy issues remain outside touched paths (see prior notes)
- `npm run audit:controls` — not re-run this session; do not regress baseline without updating `tools/audit-controls.baseline.json`
- `npx cap sync` — re-verify before any real-device test
- **Git:** one local commit on `main` — subject **`feat: MTD expense rollups, assistant facts split, scavenger handoff`** (verify with `git log -1 --oneline`). **`git push origin main` failed** in this environment (`Permission denied (publickey)`). Operator: from your normal shell (with GitHub SSH), run `git pull` (if needed) then **`git push origin main`**.

## Hard rules for the next agent
1. **Do not start M10 code without user sign-off** on transport (A/B/C — recommended B), passphrase + recovery-code model, and relay deployment green-light.
2. **Do not regress audit-controls counts.** New legit UX timer? Update `tools/audit-controls.baseline.json` in the same commit and explain why.
3. **Stable IDs (`createId()` UUIDs) and per-record `personId` are load-bearing for M10 + M11.** Don't drop either.
4. **Read-only assistant remains default for non-action chat.** When the model emits a `beacon-action` block, never auto-apply — always surface as a confirm chip.
5. **Don't undo the code-split** without checking the bundle-size impact.
6. **Backup format v4** — adding new tables means bumping the version, adding to `exportJson.ts`, schema in `importJson.ts`, clear+bulkAdd in the transaction, and counts in `backupRowCounts` + `currentDbRowCounts`. Test the round-trip.

## 2026-05-02 — CouplesWealth scavenger (read-only donor)

- **Donor:** `~/.MyAppZ/CouplesWealth` (no writes). **Policy:** `_system/context/scavenge-donor-couples-wealth.md`.
- **Runtime:** `transactionDisplay.ts` (`formatLedgerAmountDisplay`, `rollupCategoryTotals`, `buildMonthlyIncomeExpenseSeries`, `buildExpenseCategoryRollup`), `IncomeExpenseBarChart`, `BudgetHealthScoreCard`, `ExpenseCategoryRollup`; wired **Dashboard**, **Ledger**, **Reports → Monthly**, **Mission Control**.
- **Validation (this session):** `npm run test` — **142 passed**; `npm run typecheck` — clean; `eslint` on touched paths — clean. Full-repo `npm run lint` still has pre-existing errors outside these files.
- **Continuation (b):** Ledger **Top spend** sidebar (3 categories, same `YYYY-MM` as rollups); Reports CSV **`expenseCategoriesMtd`**; `buildAssistantContext` loads **`insuranceRecords`** into `calculateBudgetSummary`, adds **MTD expense total** + **top 5 categories** to the system prompt.
- **Continuation (c):** Dashboard **`MtdCategoryDonut`**; tests `exportCsv.test.ts` + `contextBuilder.test.ts`; **`exportCsv`** typed rows; **`LedgerRoute`** typed form + edit handler; **`AllocationDonut`** tooltip typed. **144** tests; typecheck + build clean.
- **Continuation (d):** **`assistantContextFacts.ts`** (pure facts + prompt string); **`collectAssistantPromptFacts`** export; extended **`AssistantContextFacts`** for UI/placeholder reuse; **`TEST_STRATEGY.md`** Vitest+IDB note. **148** tests.
- **Continuation (e):** **`BeaconChatbot`** no-provider **`placeholderReply`** — insurance + MTD top categories + screen routing hints. **148** tests.

## Next session (quick picks)
- Optional: **`BeaconChatbot`** RTL or pure **`placeholderReply`** line-builder test (currently untested string path).
- Optional: **`npm run lint`** cleanup on legacy files when a dedicated hygiene slice is scheduled.
- Unchanged blockers: **M10/M11** sign-off gates; **physical Android** M9 QA.

## Reference
- `docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md` — M10/M11 architecture + the three sign-off gates
- `docs/INTEGRATIONS_STRATEGY.md` Domain 5 — superseded for sync; other domains still authoritative
- `docs/COMPLETION_MASTER_PLAN.md` — overall narrative
- `docs/GUI_COMPLETION_CHECKLIST.md` — per-control inventory (mostly green)
- `CHANGELOG.md` Unreleased section — full per-milestone changelog for this session
