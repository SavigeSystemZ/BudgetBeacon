# Where Left Off — **active 2026-05-05** (Final Hardening pass)

## 2026-05-05 (late) — Phase 2 per-route skeleton sweep (Dashboard / Ledger / Reports)

- **Dashboard / Ledger / Reports first-load shows layout-matching skeletons** instead of `animate-pulse` text spinners ("Synchronizing Cockpit…", "Opening Ledger…", "Compiling Report Telemetry…"). Each replacement renders a `role="status"` aria region with `aria-label` and a skeleton stack that mirrors the final route's chrome (headers + metric/table/card grid), preventing visual layout shift between loading state and ready state.
  - `DashboardRoute.tsx`: header `CardSkeleton` + 4 `MetricSkeleton` + body `CardSkeleton` + 2-up grid of `CardSkeleton`.
  - `LedgerRoute.tsx`: header `CardSkeleton` + 5-row `TableRowSkeleton` block in a card-shaped wrapper.
  - `ReportsRoute.tsx`: header `CardSkeleton` + 5-tab strip + body `CardSkeleton`.
- **Validation:** `npm run validate` green; **174** tests still pass; `tsc -b` clean; eslint clean; prod build clean.
- **Remainder of useLiveQuery skeleton sweep:** ~12 routes still have bare-text loading states — Income, PayPath, StashMap, DebtCenter, Credit, TaxTaxi, DocumentStore, Subscriptions, Insurance, BeaconBridge, BudgetMissionControl, Settings. Same mechanical pattern, one route per future commit.

## 2026-05-05 (late) — Phase 2 Dexie error toast bridge

- **New `src/components/db/DexieErrorToastBridge.tsx`.** Mounted inside `<ToastProvider>` in `App.tsx` next to `SyncToastBridge`. Listens at three boundaries:
  1. `db.on("versionchange")` — another tab upgraded the schema; sticky warning toast with **Reload** action.
  2. `db.on("blocked")` — schema upgrade blocked by another tab; sticky warning telling user to close other tabs.
  3. `window.unhandledrejection` — filters reasons whose `name` starts with `Dexie` (or matches `QuotaExceededError` / `InvalidStateError`) and surfaces a destructive toast with **Reload** action. `QuotaExceededError` gets a tailored "Storage full" message. Deduplicated by `name+message` via a `useRef<Set>` so an error loop doesn't spam.
  - All Dexie errors also flow through `logger.error` for consistency with the console-hygiene pass.
- **Validation:** `npm run validate` green; **174** tests still pass; `tsc -b` clean; eslint clean; prod build clean.
- **Remainder of "useLiveQuery → skeleton/toast on first load" line:** the toast half is done at the global level; the per-route skeleton-on-first-load conversion (81 `useLiveQuery` call sites — replace each `if (!data) return <Loading/>` with a `<CardSkeleton/>` matching the route's final layout) is still open. That's a route-by-route mechanical sweep, best done one route per commit so visual diffs stay reviewable.

## 2026-05-05 (late) — Phase 2 ErrorBoundary upgrade

- **`src/components/ErrorBoundary.tsx` rewritten.** Migrated inline styles → semantic Tailwind tokens (`text-destructive`, `bg-card/90`, `border-border`, `text-muted-foreground`, etc.) so the boundary respects the active theme. Added `aria-live="assertive"` on the alert region. Captures `ErrorInfo.componentStack` in state. New **Copy report** button produces a structured report (scope, ISO timestamp, URL, user-agent, message, stack, component stack) and writes it to the clipboard via `navigator.clipboard.writeText` with a hidden-textarea + `execCommand("copy")` fallback for older WebViews / locked-down environments. Button label flips to "Report copied ✓" on success. **Try again** preserved (calls existing `reset()`). Already wired root + per-route in `App.tsx` (`scope="root"` outermost, `scope={routeName}` per lazy route).
- **Validation:** `npm run validate` green; **174** tests still pass; `tsc -b` clean; eslint clean; prod build clean. Bundle delta tiny (ErrorBoundary chunk grew by Tailwind class strings only — no new dependency).

## 2026-05-05 (late) — Phase 2 console hygiene migration

- **Console hygiene complete.** Migrated 14 raw `console.error/warn` call sites in 8 files (`src/lib/preferences/preferences.ts`, `src/lib/encoding/base64.ts`, `src/modules/reports/importJson.ts`, `src/components/setup/OnboardingWizard.tsx`, `src/components/import/LedgerImportFlow.tsx`, `src/routes/SettingsRoute.tsx`, `src/routes/DocumentStoreRoute.tsx`, `src/routes/ReportsRoute.tsx`) to `logger.{error,warn}` from `src/lib/logger.ts`. `logger.error` always forwards (errors stay visible); `logger.warn`/`info`/`log` no-op in prod unless `?debug=1`. `ErrorBoundary.tsx` keeps bare `console.error` intentionally — it's the safety-net surface and must work even if the logger module ever fails to load.
- **Validation:** `npm run validate` green — eslint clean, `tsc -b` clean, **174 tests pass** (30 files), prod `vite build` clean, PWA precache 63 entries / 1372 KiB. `npm run audit:controls` baseline matched (`setTimeout=6 mathRandom=0 alert=0 emptyOnClick=0`). `npm run audit:secrets` zero hits across **773** tracked files.
- **Phase 2 status updated in TODO.md** — console-hygiene line ticked. Remaining Phase 2: axe-core CI per route, useLiveQuery → skeleton/toast wiring on first-load, route-level ErrorBoundary UI with Reset/report button, responsive audit @ 320/380/768/1024/1440. Phase 3 M10 closeout (`relay/` Cloudflare Worker scaffold, recovery codes, OnboardingWizard sync branch) is the next critical lane after Phase 2 finishes.

## 2026-05-05 (late) — meta-system health check + cross-agent memory locality

- **Template sync gate cleared.** Repo was at `PENDING_HEALTH_CHECK` after sync to AIAST `1.23.0` (commit `a5b3e99`, then fleet repair `00a3a08`). Ran `bootstrap/emit-session-environment.sh`, `bootstrap/system-doctor.sh`, `bootstrap/validate-system.sh` — all pass (`system_ok`). Doctor warns are non-blocking working-file staleness only (`RELEASE_NOTES.md` 14 days, `_system/context/DECISIONS.md` 14 days, TODO priority signals — all pre-existing). Cleared via `bootstrap/clear-template-sync-notice.sh`.
- **New 1.23.0 / unreleased contracts now active:** `_system/APP_BUILDER_META_SYSTEM_ORCHESTRATION.md`, `APP_BUILDER_DOMAIN_ADAPTATION_RAILS.md`, `APP_BUILDER_SECURITY_AND_AUTO_CORRECTION_CONTRACT.md`, `APP_BUILDER_RELEASE_READINESS_STANDARD.md`, `APP_BUILDER_REGRESSION_AND_BENCHMARK_PROTOCOL.md`, `_system/prompt-packs/M17_APP_BUILDER_META_SYSTEM_EXECUTION.md`. App-builder execution is now domain-adaptive, containment-aware, bounded for auto-correction, and release-gated.
- **Cross-agent memory locality fix.** Created `_system/context/AGENT_SHARED_MEMORY.md` as the canonical cross-agent durable-memory surface for this repo. Rewrote Claude harness memory at `~/.claude/projects/-home-whyte--MyAppZ-BudgetBeacon/memory/project_completion_plan.md` to a thin pointer (no duplicated plan content). Pattern: tool-local memory holds **pointers**; repo-local `_system/context/` holds **content**, so Codex/Gemini/Cursor/Windsurf/etc. all read the same source of truth. Maintainer note dropped at `~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/_META_AGENT_SYSTEM/AGENT_MEMORY_LOCALITY_NOTE.md` proposing the same baseline file land in the installable template (with placeholder content) and that `AGENTS.md` working-file model section spell out the pointer-vs-content split.
- **Phase status check:** Phase 0 → 2B all committed (`386ef2a`, `11237c5`, `4385d01`, `09270ef`). Remaining Phase 2: axe-core CI per route, useLiveQuery skeleton/toast wiring, route-level ErrorBoundary UI, console hygiene (logger primitive at `src/lib/logger.ts` already exists; ~20 `console.*` call sites still need migration). Phase 3 (M10 closeout — `relay/` worker, recovery codes, OnboardingWizard sync branch, two-emulator parity smoke) is the next critical lane.
- **Uncommitted at session end:** `_system/{KEY,SYSTEM_REGISTRY,INTEGRITY_MANIFEST,.template-install,TEMPLATE_SYNC_NOTICE}.md/json/sha256` and `_system/context/CURRENT_STATUS.md` are tracked-modified from the 1.23.0 sync + sync-notice clear. Also `AIAST_CHANGELOG.md`, `_system/history/template-sync-events.jsonl`, the new `_system/APP_BUILDER_*.md` and `M17_*.md` (untracked), and `bootstrap/agent-isolation.sh` (untracked). Plus the new `_system/context/AGENT_SHARED_MEMORY.md` and updated `WHERE_LEFT_OFF.md` from this session. Operator: review and commit as `chore(meta): clear 1.23.0 sync gate + repo-local cross-agent memory pattern` (or split into two commits — meta-system sync vs memory pattern).

### Next agent — pick from

1. **Phase 2 finish (recommended next slice):** Console hygiene migration — replace ~20 `console.*` call sites in routes/components with `src/lib/logger.ts`'s `logger.{warn,error}`. Quick, low-risk, ticks one Phase 2 item without touching test wiring or CI.
2. **Phase 2 axe-core CI:** wire `vitest-axe` per route, fail on serious violations. Larger; touches `vitest.config.ts` + per-route test files.
3. **Phase 3 M10 closeout entry:** scaffold `relay/` workspace — Cloudflare Worker (~150 LOC) + Durable Objects + HMAC join token. Architecture in `docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md` (Option B).

## 2026-05-05 — Final Hardening kickoff (Phase 0)

User-approved master plan (`/home/whyte/.claude/plans/ethereal-hatching-bear.md`) drives the rest of the project to a tagged `v1.0.0` GitHub Release. Three scope decisions locked:

- **Sync:** push **M10 + M11 + M12** to fully done (Cloudflare Worker relay, recovery codes, onboarding integration, joint household, release docs).
- **APK target:** **hardened sideload APK published via GitHub Release.** No Play Store / AAB.
- **Device QA:** **Android emulator** is accepted as the M9 stand-in (Pixel 7 / API 34). M9 checklist amended accordingly.

Five-phase plan with hard gates between phases:

| Phase | Scope | Gate |
|---|---|---|
| **0** | Truth-reset & contract refresh (this session) | Docs match code; commit `docs: phase-0 truth refresh` |
| **1** | APK hardening: secrets→env, R8/ProGuard, manifest+FileProvider, version automation, plugin coverage, GH Actions release lane, distribution doc | Signed release APK boots in emulator; `git ls-files` has no keystore/password; `gradlew :app:lintRelease :app:assembleRelease` clean |
| **2** | GUI corner-to-corner: design tokens, Skeleton/Toast/FormField primitives, BeaconModal focus trap + axe CI, responsive 320–1440, async/error UX, console hygiene | axe-core CI green; manual responsive walk at 5 widths; no `console.*` in prod bundle |
| **3** | M10 closeout: relay package + recovery codes + OnboardingWizard sync branch + emulator parity smoke | Two emulator instances converge via relay |
| **4** | M11: invite/accept, per-record ownership UI, activity log, leave + key rotation | 3-device parity + leave rotates keys |
| **5** | M12 release: THREAT_MODEL / INSTALL / RECOVERY docs, release checklist, tag `v1.0.0` | Tag pushed; signed APK uploaded by `android-release.yml` |

### Phase 0 deltas (this session)

- `WHERE_LEFT_OFF.md` (this file), `TODO.md`, `PLAN.md`, `ROADMAP.md` — rewritten to reflect the approved plan; prior 2026-05-04 handoff retained below as historical record.
- `_system/VALIDATION_GATES.md` — add APK gates (assemble:release, lint:release, secrets-in-tree scan, axe a11y, emulator parity smoke).
- `docs/M9_ANDROID_QA_CHECKLIST.md` — emulator (Pixel 7 / API 34) accepted as primary M9 verification surface; physical-device run kept as optional stretch.
- Memory note `project_completion_plan.md` — refreshed to reflect 2026-05-05 final-hardening drive.

### Validation evidence (Phase 0)

- Phase 0 is doc-only. `npm run validate` baseline carried from `6637da9`: lint + typecheck clean, **174** Vitest tests pass, prod build clean. `npm run audit:controls` baseline `setTimeout=5 mathRandom=0 alert=0 emptyOnClick=0`.

### Next agent — pick up from Phase 1

1. Read the approved plan: `/home/whyte/.claude/plans/ethereal-hatching-bear.md`.
2. Phase 1 entry point: `android/app/build.gradle` (kill the hardcoded `beacon_secure_123` keystore password) and `.gitignore` (add `*.keystore`, `keystore.properties`, `*.jks`).
3. Do not regress the audit-controls baseline. New release-only timer? Update `tools/audit-controls.baseline.json` in the same commit and explain.

---

## 2026-05-04 continuation (M10.4 wiring + sync hardening)

- **`src/modules/sync/syncService.ts`:** fixed the closure bug — `wireTable(tableName)` now scopes each Yjs↔Dexie observer to its own `table` reference (previously every observer captured the last loop variable and wrote to the last table). `bootstrap(householdId, key, wsUrl?)` accepts an optional relay URL; when empty/null the service mirrors locally without opening any network connection (no more dialing the placeholder `wss://sync.budgetbeacon.app`). Added `getStatus()`, `onStatusChange()`, and `disconnect()`.
- **`src/components/sync/SyncStatusBadge.tsx`:** small a11y-labeled pill (Local-only / Connecting / Synced / Offline / Sync error). Mounted in the desktop sidebar footer and the mobile header next to the Beacon wordmark.
- **`src/components/sync/AuthSyncCard.tsx`:** opt-in Sync & Account card in Settings. Signup/login with passphrase (Argon2-derived KEK; AES-GCM unwrap of household key, all client-side). Relay URL input (persisted to `localStorage["beacon_sync_relay_url"]`); "Start sync" calls `syncService.bootstrap(...)`. Sign-out drops the in-memory household key without touching Dexie data. Effective mode is derived from `accounts.length` rather than via setState-in-effect.
- **Validation:** `npm run validate` green; **174** Vitest tests pass; `npm run audit:controls` baseline unchanged (`setTimeout=5 mathRandom=0 alert=0 emptyOnClick=0`); production build clean.
- **Notes for next agent:** the relay is still undeployed — sign-up creates a local-only account and key envelope; the "Start sync" button is safe to press without a URL (mirrors locally only). M10/M11 gates around relay deployment + recovery-code model remain open even though the auth/crypto/sync code is wired.

## Earlier — paused 2026-05-03

> **Session stop:** **`main`** is clean for the **2026-05-03** pause. Primary batch: **`ee5ded6`** (*feat: Beacon modals, assistant grounding, CI, debt trajectory polish*). Tip may include an additional **handoff doc** commit after that; use **`git log -2 --oneline`**. Not pushed from this environment. **`npm run validate`** was green with **164** Vitest tests; **`npm run audit:controls`** OK (**`setTimeout=5`**, **`alert=0`**). Next session: **`git pull`** / **`git push`** using the operator account **per `GIT_REMOTE_AND_SYNC_PROTOCOL.md`** when sharing; otherwise continue **`docs/UNGATED_PRODUCT_BACKLOG.md`** Tier A (e.g. **`docs/M9_ANDROID_QA_CHECKLIST.md`** on hardware). **M10/M11** (sync / joint households) stay **gated** until explicit architecture sign-off.
>
> **Status:** M0–M8 closed; M9 partial (code-split). Earlier 2026-05-02 CouplesWealth scavenger + rollups noted in sections below.
>
> **`_system/checkpoints/`** was left **untracked** (agent mid-session snapshots); delete or `.gitignore` locally if undesired—or commit only when you intentionally version a checkpoint export.

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
- Validation run in this session: None
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


## Session Snapshot
- **Objective:** Finalize the application frontend and backend (M10 Backend Sync).
- **Status:** Complete. Auth, E2EE Crypto, and Yjs CRDT Mirroring successfully implemented and tested.


## Last Completed Work
- Unlocked M10 (Auth + Cross-Device Sync) following the recommended Architecture Option B.
- Created `authService` mapping client-side ECDH / AES-GCM keys.
- Implemented `crypto.ts` with PBKDF2 derivation, ECDH key wrapping, and AES-GCM encryption envelope for strict E2EE.
- Created `syncService.ts` mirroring 16 Dexie tables to `y-websocket` Yjs documents dynamically.


## Validation Run
- **Command:** `npm run validate`
- **Result:** Success (Exit Code 0). All 174 tests across frontend and new sync/crypto backend pass perfectly. `tsc -b` and `eslint` clean. Production Vite build fully completes.


## Next Best Step
- Build the `AuthModal.tsx` and integrate the `syncService.bootstrap` call into the React tree lifecycle.
- Add a "Sync Status" indicator to the bottom navigation bar (M10.4 completion).


## Handoff Packet
- **Agent:** Gemini
- **Timestamp:** 2026-05-04
- **Objective:** Meta system completeness
- **Next best step:** Proceed with outstanding priority work


## Meta-sync reconciled 2026-05-14T21:20:44Z

- **Sync window:** PENDING emitted 2026-05-14T21:05:13Z by `update-template.sh` (event=update-template).
- **Template version:** 1.23.0 → 1.23.0.
- **Changeset:** missing_installed=0, drifted_refreshed=75, always_refresh_applied=20.
- **Checks:** integrity=ok, host_settings_baseline=ok, system_awareness=ok, host_adapter_alignment=ok, instruction_layer=ok, host_settings_apply=ok.
- **Project-context relevance:** ⚠ overlap with last WHERE_LEFT_OFF note: `AGENTS.md`, `_system/context/AGENT_SHARED_MEMORY.md`, `AIAST_CHANGELOG.md`, `bootstrap/validate-system.sh`. Re-read prior note + targeted re-test before resuming.
- **Status:** ok — proceed with previously-noted project work.

## Meta-sync reconciled 2026-05-16T15:42:31Z

- **Sync window:** PENDING emitted 2026-05-16T15:26:35Z by `update-template.sh` (event=update-template).
- **Template version:** 1.23.0 → 1.23.0.
- **Changeset:** missing_installed=0, drifted_refreshed=78, always_refresh_applied=20.
- **Checks:** integrity=ok, host_settings_baseline=ok, system_awareness=ok, host_adapter_alignment=ok, instruction_layer=ok, host_settings_apply=ok.
- **Project-context relevance:** ⚠ overlap with last WHERE_LEFT_OFF note: `AGENTS.md`, `bootstrap/validate-system.sh`, `_system/context/AGENT_SHARED_MEMORY.md`, `AIAST_CHANGELOG.md`. Re-read prior note + targeted re-test before resuming.
- **Status:** ok — proceed with previously-noted project work.

## Meta-sync reconciled 2026-05-16T18:02:08Z

- **Sync window:** PENDING emitted 2026-05-16T17:47:05Z by `update-template.sh` (event=update-template).
- **Template version:** 1.23.0 → 1.23.0.
- **Changeset:** missing_installed=0, drifted_refreshed=78, always_refresh_applied=20.
- **Checks:** integrity=ok, host_settings_baseline=ok, system_awareness=ok, host_adapter_alignment=ok, instruction_layer=ok, host_settings_apply=ok.
- **Project-context relevance:** ⚠ overlap with last WHERE_LEFT_OFF note: `AIAST_CHANGELOG.md`, `_system/context/AGENT_SHARED_MEMORY.md`, `bootstrap/validate-system.sh`, `AGENTS.md`. Re-read prior note + targeted re-test before resuming.
- **Status:** ok — proceed with previously-noted project work.

## Meta-sync reconciled 2026-05-16T23:15:05Z

- **Sync window:** PENDING emitted 2026-05-16T23:00:20Z by `update-template.sh` (event=update-template).
- **Template version:** 1.23.0 → 1.23.0.
- **Changeset:** missing_installed=0, drifted_refreshed=82, always_refresh_applied=20.
- **Checks:** integrity=ok, host_settings_baseline=ok, system_awareness=ok, host_adapter_alignment=ok, instruction_layer=ok, host_settings_apply=ok.
- **Project-context relevance:** ⚠ overlap with last WHERE_LEFT_OFF note: `bootstrap/validate-system.sh`, `AGENTS.md`, `AIAST_CHANGELOG.md`, `_system/context/AGENT_SHARED_MEMORY.md`. Re-read prior note + targeted re-test before resuming.
- **Status:** ok — proceed with previously-noted project work.

## Meta-sync reconciled 2026-05-17T01:04:34Z

- **Sync window:** PENDING emitted 2026-05-17T00:47:45Z by `update-template.sh` (event=update-template).
- **Template version:** 1.23.0 → 1.23.0.
- **Changeset:** missing_installed=0, drifted_refreshed=82, always_refresh_applied=27.
- **Checks:** integrity=ok, host_settings_baseline=ok, system_awareness=ok, host_adapter_alignment=ok, instruction_layer=ok, host_settings_apply=ok.
- **Project-context relevance:** ⚠ overlap with last WHERE_LEFT_OFF note: `bootstrap/validate-system.sh`, `_system/context/AGENT_SHARED_MEMORY.md`, `AGENTS.md`, `AIAST_CHANGELOG.md`. Re-read prior note + targeted re-test before resuming.
- **Status:** ok — proceed with previously-noted project work.

## Meta-sync reconciled 2026-05-17T03:36:49Z

- **Sync window:** PENDING emitted 2026-05-17T03:20:20Z by `update-template.sh` (event=update-template).
- **Template version:** 1.23.0 → 1.23.0.
- **Changeset:** missing_installed=0, drifted_refreshed=83, always_refresh_applied=27.
- **Checks:** integrity=ok, host_settings_baseline=ok, system_awareness=ok, host_adapter_alignment=ok, instruction_layer=ok, host_settings_apply=ok.
- **Project-context relevance:** ⚠ overlap with last WHERE_LEFT_OFF note: `_system/context/AGENT_SHARED_MEMORY.md`, `AGENTS.md`, `AIAST_CHANGELOG.md`, `bootstrap/validate-system.sh`. Re-read prior note + targeted re-test before resuming.
- **Status:** ok — proceed with previously-noted project work.

## Meta-sync reconciled 2026-05-17T19:37:14Z

- **Sync window:** PENDING emitted 2026-05-17T19:19:30Z by `update-template.sh` (event=update-template).
- **Template version:** 1.23.0 → 1.23.0.
- **Changeset:** missing_installed=0, drifted_refreshed=84, always_refresh_applied=27.
- **Checks:** integrity=ok, host_settings_baseline=ok, system_awareness=ok, host_adapter_alignment=ok, instruction_layer=ok, host_settings_apply=ok.
- **Project-context relevance:** ⚠ overlap with last WHERE_LEFT_OFF note: `AIAST_CHANGELOG.md`, `_system/context/AGENT_SHARED_MEMORY.md`, `bootstrap/validate-system.sh`, `AGENTS.md`. Re-read prior note + targeted re-test before resuming.
- **Status:** ok — proceed with previously-noted project work.

## Meta-sync reconciled 2026-05-23T16:01:35Z

- **Sync window:** PENDING emitted 2026-05-23T15:39:45Z by `update-template.sh` (event=update-template).
- **Template version:** 1.23.0 → 1.23.0.
- **Changeset:** missing_installed=0, drifted_refreshed=99, always_refresh_applied=27.
- **Checks:** integrity=ok, host_settings_baseline=ok, system_awareness=ok, host_adapter_alignment=ok, instruction_layer=ok, host_settings_apply=ok.
- **Project-context relevance:** ⚠ overlap with last WHERE_LEFT_OFF note: `bootstrap/validate-system.sh`, `_system/VALIDATION_GATES.md`, `_system/context/AGENT_SHARED_MEMORY.md`, `AGENTS.md`, `AIAST_CHANGELOG.md`, `bootstrap/system-doctor.sh`. Re-read prior note + targeted re-test before resuming.
- **Status:** ok — proceed with previously-noted project work.

## Meta-sync reconciled 2026-05-23T19:47:20Z

- **Sync window:** PENDING emitted 2026-05-23T19:24:37Z by `update-template.sh` (event=update-template).
- **Template version:** 1.24.0 → 1.24.0.
- **Changeset:** missing_installed=0, drifted_refreshed=108, always_refresh_applied=31.
- **Checks:** integrity=ok, host_settings_baseline=ok, system_awareness=ok, host_adapter_alignment=ok, instruction_layer=ok, host_settings_apply=ok.
- **Project-context relevance:** ⚠ overlap with last WHERE_LEFT_OFF note: `AGENTS.md`, `AIAST_CHANGELOG.md`, `bootstrap/validate-system.sh`, `_system/context/AGENT_SHARED_MEMORY.md`, `_system/VALIDATION_GATES.md`, `bootstrap/system-doctor.sh`. Re-read prior note + targeted re-test before resuming.
- **Status:** ok — proceed with previously-noted project work.

## Meta-sync reconciled 2026-05-23T20:57:15Z

- **Sync window:** PENDING emitted 2026-05-23T20:36:21Z by `update-template.sh` (event=update-template).
- **Template version:** 1.24.0 → 1.24.0.
- **Changeset:** missing_installed=0, drifted_refreshed=104, always_refresh_applied=31.
- **Checks:** integrity=ok, host_settings_baseline=ok, system_awareness=ok, host_adapter_alignment=ok, instruction_layer=ok, host_settings_apply=ok.
- **Project-context relevance:** ⚠ overlap with last WHERE_LEFT_OFF note: `bootstrap/validate-system.sh`, `_system/VALIDATION_GATES.md`, `_system/context/AGENT_SHARED_MEMORY.md`, `AIAST_CHANGELOG.md`, `AGENTS.md`, `bootstrap/system-doctor.sh`. Re-read prior note + targeted re-test before resuming.
- **Status:** ok — proceed with previously-noted project work.

## Meta-sync reconciled 2026-05-23T21:37:24Z

- **Sync window:** PENDING emitted 2026-05-23T21:16:05Z by `update-template.sh` (event=update-template).
- **Template version:** 1.24.0 → 1.24.0.
- **Changeset:** missing_installed=0, drifted_refreshed=110, always_refresh_applied=39.
- **Checks:** integrity=ok, host_settings_baseline=ok, system_awareness=ok, host_adapter_alignment=ok, instruction_layer=ok, host_settings_apply=ok.
- **Project-context relevance:** ⚠ overlap with last WHERE_LEFT_OFF note: `bootstrap/validate-system.sh`, `bootstrap/system-doctor.sh`, `_system/VALIDATION_GATES.md`, `_system/context/AGENT_SHARED_MEMORY.md`, `AGENTS.md`, `AIAST_CHANGELOG.md`. Re-read prior note + targeted re-test before resuming.
- **Status:** ok — proceed with previously-noted project work.

## Meta-sync reconciled 2026-05-28T05:43:14Z

- **Sync window:** PENDING emitted 2026-05-28T05:21:37Z by `update-template.sh` (event=update-template).
- **Template version:** 1.24.0 → 1.24.0.
- **Changeset:** missing_installed=9, drifted_refreshed=117, always_refresh_applied=39.
- **Checks:** integrity=ok, host_settings_baseline=ok, system_awareness=ok, host_adapter_alignment=ok, instruction_layer=ok, host_settings_apply=ok.
- **Project-context relevance:** ⚠ overlap with last WHERE_LEFT_OFF note: `_system/context/AGENT_SHARED_MEMORY.md`, `bootstrap/system-doctor.sh`, `bootstrap/validate-system.sh`, `_system/VALIDATION_GATES.md`, `AGENTS.md`, `AIAST_CHANGELOG.md`. Re-read prior note + targeted re-test before resuming.
- **Status:** ok — proceed with previously-noted project work.
