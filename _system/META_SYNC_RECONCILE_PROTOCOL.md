# Meta-Sync Reconcile Protocol

**Status:** active since 1.24.0 (S19e)
**Purpose:** Make every TEMPLATE → downstream sync **legible and verified by the next agent that walks in.**
**Related contracts:** `HOST_SETTINGS_BASELINE.md`, `INSTRUCTION_PRECEDENCE_CONTRACT.md`, `EXECUTION_PROTOCOL.md`, `WHERE_LEFT_OFF.md`.

---

## Problem this solves

Before this protocol: a downstream got updated by `update-template.sh` silently. The next agent (Claude/Codex/Gemini/etc.) walked in, started project work, and only discovered drift when something broke. There was no handoff signal.

After: every successful update writes a **drop-file marker**. The next agent's canonical startup sequence detects the marker, runs a reconciliation pass (integrity + host-settings + awareness + auto-merge), notes the result in `WHERE_LEFT_OFF.md`, and only then begins project-specific work.

## Files

All under `_system/agent-state/meta-sync/`:

| File | Lifecycle | Format | Purpose |
|------|-----------|--------|---------|
| `PENDING.json` | written by `update-template.sh`; deleted by `reconcile-meta-sync.sh` | JSON envelope | sentinel + changeset detail |
| `history.jsonl` | append-only | one JSON object per line | ledger of every completed reconcile (sync timestamp, reconcile timestamp, check results, actor, host) |
| `LATEST_RECONCILE.json` | overwritten on each reconcile | JSON envelope | last reconcile summary (for dashboards) |

The directory and the `agent-state/` parent are isolation-aware (per `AGENT_INSTANCE_ISOLATION_POLICY.md`) — meta-sync state is project-local; never bleeds across apps.

## `PENDING.json` schema

```json
{
  "schema_version": "1.0.0",
  "kind": "meta_sync_pending",
  "emitted_at": "2026-05-14T19:30:00Z",
  "emitter": {
    "tool": "bootstrap/update-template.sh",
    "actor": "<unix-user>",
    "host_running": "claude-code|codex-cli|gemini-cli|windsurf|cursor|copilot|unknown",
    "host_detected_via": "$AIAST_HOST_ADAPTER|argv0|none"
  },
  "template": {
    "version_before": "1.23.0",
    "version_after": "1.23.0",
    "source_root_basename": "TEMPLATE"
  },
  "changeset": {
    "missing_installed": ["..."],
    "drifted_refreshed": ["..."],
    "always_refresh_entries_applied": ["..."],
    "host_settings_active": 6,
    "host_settings_passing": 6
  },
  "next_step": "bash bootstrap/reconcile-meta-sync.sh"
}
```

## Reconcile flow

`bootstrap/reconcile-meta-sync.sh` runs the following in order. Each step's result joins the envelope; the reconcile is `ok` iff every step is `ok` or `skipped_unavailable`.

1. **integrity** — `bootstrap/verify-integrity.sh --check --target .`
2. **host_settings** — `bootstrap/check-host-settings-baseline.sh .` (only if file present; older downstreams may not have it yet)
3. **system_awareness** — `bootstrap/check-system-awareness.sh .`
4. **host_adapter_alignment** — `bootstrap/check-host-adapter-alignment.sh .` (if available)
5. **instruction_layer** — `bootstrap/validate-instruction-layer.sh .` (if available)
6. **host_settings_apply** — `bootstrap/apply-host-settings.sh --target .` (auto-merge meta-managed keys into preserve-first siblings; idempotent — `unchanged` on a fresh sync)
7. **project_context_relevance** — best-effort: cross-reference `PENDING.changeset.*` paths against `WHERE_LEFT_OFF.md` last-mentioned files; flag if any overlap. Informational only.
8. **handoff_note** — append a one-line "Meta-sync reconciled" entry to `WHERE_LEFT_OFF.md` with the timestamp, check rollup, and relevance flag.
9. **archive** — append the full envelope to `history.jsonl`; write `LATEST_RECONCILE.json`; **delete** `PENDING.json`.

**Refusal:** if any of steps 1–5 fail, reconcile stops, does NOT delete `PENDING.json`, and emits `meta_sync_reconcile_blocked` with the failing step. Operator must fix the underlying issue and re-run. The handoff note still gets appended with the blockage info.

## Startup gate

`bootstrap/check-pending-meta-sync.sh` is the **first thing** every agent runs after reading `AGENTS.md`:

- If `PENDING.json` does not exist → emit `meta_sync_pending_none` (rc=0). Proceed.
- If `PENDING.json` exists → emit `meta_sync_pending` with the changeset summary and the hint `bash bootstrap/reconcile-meta-sync.sh`. Exit code:
  - default: rc=0 (informational; downstream agent may choose to proceed)
  - `--strict` flag: rc=1 (used in CI / autopilots that must not proceed across an unreconciled sync)

Agents should treat the informational mode as a **prompt to reconcile first**, not as silent permission to skip. The canonical pattern:

```bash
bash bootstrap/check-pending-meta-sync.sh && {
  # No pending sync, or operator chose to proceed.
  if [[ -f _system/agent-state/meta-sync/PENDING.json ]]; then
    bash bootstrap/reconcile-meta-sync.sh
  fi
}
```

Or, the one-liner the host-settings UserPromptSubmit hook uses:

```bash
test -f _system/agent-state/meta-sync/PENDING.json && \
  echo "[aiaast] META-SYNC PENDING — run bash bootstrap/reconcile-meta-sync.sh"
```

## Cross-reference with `WHERE_LEFT_OFF.md`

The handoff note appended by reconcile follows this shape:

```markdown
## Meta-sync reconciled 2026-05-14T19:45:00Z

- **Sync window:** PENDING emitted 2026-05-14T19:30:00Z (15m ago) by `update-template.sh`.
- **Template version:** 1.23.0 → 1.23.0 (no version bump).
- **Files refreshed:** 7 always-refresh entries (.claude/settings.aiaast.json, .codex/config.aiaast.toml, ...).
- **Files installed:** 0 missing.
- **Checks:** integrity=ok, host_settings=ok (active=6 passing=6), system_awareness=ok, instruction_layer=ok.
- **Apply-host-settings:** total=6 unchanged=6 merged=0 (claude native; others already merged).
- **Project-context relevance:** none of the refreshed files overlap with the last project-work note above. Safe to resume project work.
- **Next:** proceed with previously-noted work — no meta-system adjustment required.
```

When relevance hits (refreshed file IS the topic of the last note), the line becomes:

```markdown
- **Project-context relevance:** ⚠ refreshed `bootstrap/lib/aiaast-lib.sh` overlaps with the last WHERE_LEFT_OFF note (was working on lib changes). Re-read that note + run a targeted re-test before resuming.
```

## Host integration

Every host's `*.aiaast.*` settings file gains a meta-sync-aware element:

- **Claude Code** (`.claude/settings.aiaast.json` → `UserPromptSubmit` hook): one-line banner — `[aiaast] template-version=<v> integrity=ok|drift meta-sync=pending|clean`.
- **Codex CLI** (`.codex/config.aiaast.toml` → `[integrity]` section): `verify_meta_sync_before_handoff = true`.
- **Gemini / Windsurf / Cursor / Copilot:** `integrity.verify_meta_sync_before_handoff: true` JSON key.

Hosts that don't have native hooks rely on the AGENTS.md canonical startup step + the operator/agent running `check-pending-meta-sync.sh` manually (it's a one-line invocation that's cheap to run on every session start).

## Refusal conditions

- `PENDING.json` malformed (schema mismatch) → reconcile emits `meta_sync_reconcile_blocked: pending_malformed`; operator inspects + can `--force` to skip.
- One of the check steps fails → see "Refusal" under Reconcile flow.
- Trying to emit a marker inside the parent TEMPLATE — refused by `aiaast_assert_non_root_for_repo_writes` + the explicit parent-template guard (mirror of `apply-host-settings.sh` pattern).

## Smoke contract

`_TEMPLATE_FACTORY/smoke-meta-sync-reconcile.sh` covers:

1. fresh downstream, no marker → `check-pending` reports `none`, reconcile exits 0 no-op
2. update-template.sh against fresh downstream → marker written, schema valid
3. reconcile happy path → all checks pass, PENDING deleted, history.jsonl grows by 1, WHERE_LEFT_OFF note appended
4. reconcile with simulated integrity failure → blocked, PENDING preserved, handoff note records blockage
5. project-context relevance hit → ⚠ note in WHERE_LEFT_OFF
6. `check-pending --strict` against a pending marker → rc=1
7. idempotent reconcile (run twice in a row when no PENDING) → second is a no-op

## Resume points

- **S19e (this slice):** marker emit, reconcile, startup gate, host integration, smoke, fleet rollout.
- **S19f (optional):** fleet-level aggregator that walks every downstream and reports the count of repos with pending markers older than 24h (operator dashboard).
