# Agent Shared Memory

Cross-agent durable memory for this repo. **All** agents (Claude, Codex, Gemini, Cursor, Windsurf, Copilot, Aider, etc.) should read and write here so durable knowledge is shared. Tool-local memory stores (e.g. `~/.claude/projects/.../memory/`) should be **pointers** into this file, not the source of truth.

## Why repo-local

- Tool-local memory is invisible to other agents — Codex cannot read Claude's `~/.claude/...` cache and vice versa.
- Repo-local memory is committed alongside code, survives reinstalls, and follows the repo when it is cloned to another host.
- AGENTS.md already designates `_system/context/*.md` as the canonical durable-memory surface. This file extends `MEMORY.md` with project-execution memory specifically.

## How to use

- **Read first.** When picking up work, read this file plus `WHERE_LEFT_OFF.md`, `TODO.md`, `_system/context/CURRENT_STATUS.md`.
- **Write durable knowledge only.** Architecture invariants, locked scope decisions, load-bearing primitives, surprising constraints. Not transient task state.
- **Tool-local pointers.** Claude's harness memory (`~/.claude/projects/-home-whyte--MyAppZ-BudgetBeacon/memory/MEMORY.md`) keeps a thin pointer to this file rather than duplicating content.

## Active project memory

### Final Hardening master plan (locked 2026-05-05)

User-approved plan: `/home/whyte/.claude/plans/ethereal-hatching-bear.md`. Scope decisions:

- Push **M10 + M11 + M12** to fully done (relay deploy, recovery codes, onboarding integration, joint household, release docs).
- **APK target:** hardened sideload APK published via GitHub Release. **No Play Store / AAB.**
- **Device QA:** Android emulator (Pixel 7 / API 34) is the M9 stand-in; physical-device run optional.

Five phases, hard gates between:

1. **Phase 0** ✅ — Truth-reset & contract refresh (commit `386ef2a`).
2. **Phase 1** ✅ — APK hardening (commit `11237c5`): keystore env vars, R8 + ProGuard, manifest tightening, version automation from `package.json`, GH Actions release + emulator-smoke lanes.
3. **Phase 2A** ✅ — Modal a11y, Toast/Skeleton/FormField primitives, semantic color tokens (commit `4385d01`).
4. **Phase 2B** ✅ — Cross-route semantic color sweep, sync toast bridge, Suspense skeleton (commit `09270ef`).
5. **Phase 2 remainder** — axe-core CI per route, responsive audit (320–1440), useLiveQuery → skeleton/toast, route-level ErrorBoundary, console hygiene.
6. **Phase 3** — M10 closeout: `relay/` Cloudflare Worker (~150 LOC) + Durable Objects + HMAC join token, recovery codes (10 single-use, KEK-encrypted), `OnboardingWizard` sync branch + QR add-device, two-emulator parity smoke.
7. **Phase 4** — M11 joint household: invite (24 h HMAC) → accept (pubkey exchange via relay) → per-record ownership UI from `personId` → activity log Dexie table → leave + key rotation.
8. **Phase 5** — M12 release: `docs/THREAT_MODEL.md`, `INSTALL.md`, `RECOVERY.md`, release checklist, tag `v1.0.0` → `android-release.yml` publishes signed APK + mappings + SHA-256 checksums.

### Validation baseline (carry through every phase)

- `npm run validate` green at HEAD: lint + typecheck + 174 Vitest tests + prod build clean.
- `npm run audit:controls` baseline `setTimeout=6 mathRandom=0 alert=0 emptyOnClick=0` (Phase 2A added one documented Toast.tsx timer).
- `npm run audit:secrets` zero hits across tracked files.

### Hard rules carried forward

1. Stable IDs (`createId()` UUIDs) and per-record `personId` are load-bearing for M10/M11 — never drop.
2. Backup format **v4** covers all 18 tables incl. documents Blob (base64); v1/v2/v3 still readable on import.
3. Read-only assistant default; `beacon-action` JSON blocks always render as confirm chips, never auto-applied.
4. Sync is opt-in — local-only is the default path. "Start sync" with empty URL mirrors locally only (no dead-relay dialing).
5. Don't regress audit-controls baseline without updating `tools/audit-controls.baseline.json` in the same commit.

### Key surfaces / primitives — don't rebuild

- `src/modules/auth/authService.ts` — `signUp` / `login` / `logout` / `restoreSessionPromptIfNeeded`.
- `src/modules/crypto/crypto.ts` — `derivePassphraseKey`, `wrap/unwrapKey`, `encryptForSync`, `decrypt`. Recovery codes will reuse `derivePassphraseKey`.
- `src/modules/sync/syncService.ts` — singleton; `getStatus()`, `onStatusChange(listener)`, `bootstrap(householdId, key, wsUrl?)`, `disconnect()`. M11 plugs in here.
- `src/components/sync/{SyncStatusBadge,AuthSyncCard,SyncToastBridge}.tsx` — extend, don't replace.
- `src/components/ui/{EmptyState,Skeleton,Toast,FormField,BeaconModal}.tsx` — canonical primitives. `BeaconModal` has full focus trap + `aria-modal` as of Phase 2A.
- `src/index.css` semantic tokens (`--color-success/warning/destructive/info`) read from per-theme HSL — extending themes means extending these vars, not adding hard-coded tailwind colors.

### Operational facts

- Git remote: `origin` = `git@github.com:SavigeSystemZ/BudgetBeacon.git`. Operator handles push from their shell.
- Architecture doc: `docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md` (Option B signed off 2026-05-05).
- Release pipeline: `.github/workflows/android-release.yml` + `android-emulator-smoke.yml` already wired (Phase 1).
