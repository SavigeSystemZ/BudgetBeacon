# Decisions

> _Timestamp: 2026-06-02. Durable decisions for **Budget Beacon**. (Prior contents were generic AIAST-template governance entries carried in by the template sync; replaced with this repo's real decisions.)_

Record durable decisions here.

## Entry format

- Date / Decision / Reason / Impact / Follow-up / Revisit trigger.

## Entries

### 2026-06-02 — Git model: local-first authority, GitHub as redundant mirror

- **Decision:** The local repository is authoritative. `origin` (`git@github.com:SavigeSystemZ/BudgetBeacon.git`) is a full tracked-file mirror for redundancy/backup only — not a separate planning surface, branch farm, or PR-gated workflow. Default branch is `main`; topic branches are short-lived exceptions.
- **Reason:** Single-developer, local-first app; matches the operator's stated policy and `_system/GIT_REMOTE_AND_SYNC_PROTOCOL.md`.
- **Impact:** Validated local `main` is pushed directly to `origin/main`. The `chore/aiast-repair-20260505` branch is consolidated into `main` and retired.
- **Revisit trigger:** Multi-machine or multi-contributor work begins.

### 2026-06-02 — Repo role is downstream-app; layout is hybrid (root-level)

- **Decision:** This repo is a **downstream app** carrying its own tailorable copy of the AIAST meta-system, not the AIAST template. App code stays at top-level `src/`/`public/`/`tools/` (hybrid layout); the empty 1.24.0 `app/` scaffold placeholder is not used.
- **Reason:** The 1.24.0 sync shipped `_system/.aiast-role.json` with the template default `parent-template`, mislabeling the repo and surfacing a misleading "blank app" directive. Budget Beacon is a far-along app with established root-level structure.
- **Impact:** `_system/.aiast-role.json` set to `downstream-app`; `_system/app-local-namespace.json` created; two app-identity validators made hybrid/camelCase aware (recorded in the self-improvement ledger, tagged generic).
- **Revisit trigger:** A deliberate migration to the isolated `app/` layout.

### 2026-05-05 — Final Hardening scope locked

- **Decision:** Drive M10 + M11 + M12 to done. **APK target:** hardened sideload APK via GitHub Release — **no Play Store / AAB**. Device QA via Android emulator (Pixel 7 / API 34) as the M9 stand-in.
- **Reason:** Operator-approved plan (`/home/whyte/.claude/plans/ethereal-hatching-bear.md`); see `_system/context/AGENT_SHARED_MEMORY.md`.
- **Impact:** Five phases with hard gates; sync architecture Option B (E2EE-CRDT) signed off (`docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md`).
- **Revisit trigger:** Transport model, recovery-code model, or relay-hosting assumptions change.

### 2026-05-05 — Sync is opt-in; assistant is read-only by default

- **Decision:** Local-only is the default path; "Start sync" with an empty URL mirrors locally only (no dead-relay dialing). The assistant never auto-applies writes — `beacon-action` blocks always render as confirm chips.
- **Reason:** Trust and data-safety for sensitive financial data; avoid overclaiming sync/AI capability before it exists.
- **Impact:** Load-bearing for M10/M11. Stable `createId()` UUIDs and per-record `personId` must never be dropped. Backup format **v4** (18 tables incl. documents Blob) with v1–v3 import tolerance.
- **Revisit trigger:** A change to the sync/auth trust model.
