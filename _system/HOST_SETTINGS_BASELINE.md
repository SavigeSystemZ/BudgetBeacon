# Host Settings Baseline (HOST_SETTINGS_BASELINE)

**Status:** active since 1.24.0 (S19a + S19b plus Antigravity — all 7 primary hosts active)
**Scope:** every primary AI host adapter listed in `_system/host-adapter-manifest.json`
**Source of truth:** `_system/host-adapter-manifest.json` → `host_settings` block per adapter
**Related contracts:** `HOST_ADAPTER_POLICY.md`, `INSTRUCTION_PRECEDENCE_CONTRACT.md`, `TOOL_MEMORY_ISOLATION_STAMP.md`

---

## Why this exists

`TEMPLATE` ships adapter surface files (`CLAUDE.md`, `CODEX.md`, `.cursorrules`, etc.) so every host reads the same repo contract. But each host *also* has a settings file — permissions allowlists, hooks, MCP wiring, model defaults — that lives outside the repo contract and would otherwise be re-invented per app. The baseline closes that gap so:

1. The fleet inherits a vetted permissions allowlist (no re-prompting for safe `bash`, `gh`, `bq` commands across 31 repos).
2. The fleet inherits a vetted hook contract (integrity checks on `Stop`, non-root guard on writes, tool-memory stamp helper on memory writes).
3. Policy changes (tightening a permission, adding a hook) can propagate via one TEMPLATE edit + the next preserve-first sweep.
4. Per-app customization still works — the meta-managed file is a sibling, not a clobber.

## The hybrid split

Each adapter that supports host-level settings ships **two files**:

| File | Lifecycle | Audience |
|------|-----------|----------|
| `<host-dir>/settings.json` (or `config.toml`, etc.) | **Preserve-first** — written once on scaffold, then app-owned | Per-app operators add project-specific permissions, env vars, status lines |
| `<host-dir>/settings.aiaast.json` (or `.aiaast.toml`, etc.) | **Always-refresh** — meta-managed, regenerated on every `update-template.sh` sweep | Meta-system maintainers; fleet-wide policy lives here |

**Marker:** every `.aiaast.*` file carries a top-level field:

```json
"$aiaast": {
  "managed_by": "_AI_AGENT_SYSTEM_TEMPLATE",
  "policy_doc": "_system/HOST_SETTINGS_BASELINE.md",
  "preserve_first_sibling": ".claude/settings.json"
}
```

The marker is the linter's tamper signal — `check-host-settings-baseline.sh` refuses to pass without it.

## Merge semantics per host

Hosts vary in whether they natively merge multiple settings files. The baseline accommodates both:

| Host | Native merge? | How baseline applies |
|------|---------------|----------------------|
| Claude Code | Yes — `settings.json` + `settings.local.json` precedence stack | `.aiaast.json` is the meta layer; `apply-host-settings.sh` records action=unchanged (native). Operator references it via the Claude settings stack. |
| Codex CLI | No — single `config.toml` | `apply-host-settings.sh` TOML key-merges `.aiaast.toml` into `config.toml`. Preserves non-conflicting app keys; app wins on scalar conflict (shadowed records the meta value). |
| Gemini CLI | No native layering — single project `settings.json` | JSON deep-merge via apply helper. |
| Windsurf | No — single project-local `settings.json` | JSON deep-merge via apply helper. |
| Cursor | No — single `.cursor/settings.json` (+ `.cursor/mcp.json` for MCP) | JSON deep-merge via apply helper; rules already covered by S12 adapter surface flow. |
| Copilot | No — repo-scoped `.github/copilot-config.json` | JSON deep-merge via apply helper. Rules surface (`.github/copilot-instructions.md`) stays under S12 adapter flow. |
| Antigravity | Project `.antigravitycli/settings.json`; user-local MCP discovery uses Gemini/Antigravity config. | JSON deep-merge via apply helper. Keep `~/.gemini/config/mcp_config.json` valid JSON in user-local config, not tracked repo files. |

## Hook contract (Claude Code reference)

Every meta-managed `.aiaast.json` ships at minimum:

- **`PreToolUse(Bash)`:** call `bootstrap/lib/check-write-as-non-root.sh` so write operations refuse to run as root. (Defensive — `aiaast_assert_non_root_for_repo_writes` is the lib-level guard; the hook elevates it to a host-level pre-flight.)
- **`PostToolUse(Edit|Write)`:** append the change to `_system/agent-state/audit/host-edits.jsonl` for downstream telemetry (feeds S17b `aggregate-fleet-bleed-events.sh`).
- **`Stop`:** run `bootstrap/verify-integrity.sh --check --target .` and surface the result. Closes the loop on tamper detection at end-of-turn.
- **`UserPromptSubmit`:** print a one-line status banner from `bootstrap/print-startup-banner.sh` so the operator sees which managed-file version + integrity status is in effect.

Hosts without comparable hook surfaces (Cursor, Copilot) get a settings-only baseline (instruction-file allowlist, MCP wiring, tool-memory contract refs, integrity verify-before-handoff hint) without the executable hook block.

## Integrity wiring

`.aiaast.*` files are in `aiaast_print_managed_files`, so they flow into:

- `SYSTEM_REGISTRY.json` — listed with category `host-settings`.
- `INTEGRITY_MANIFEST.sha256` — hashed; tamper trips `verify-integrity.sh`.
- `KEY.md` — categorized by `aiaast_path_category`.
- `SUPER_TEMPLATE_MASTER_MAP.md` — appears in the host-settings section.

Preserve-first sibling files (`settings.json`) are NOT in the managed-file set — they are app surface and the app owns them. (Parallel to how `_system/tool-memory/<adapter>-memory.md` is app surface in the isolation contract.)

## Always-refresh enrollment

All `.aiaast.*` files appear in `always_refresh_files` in `bootstrap/update-template.sh`. The S17a regression smoke (`smoke-always-refresh.sh`) auto-tracks the array, so this protection is mechanically guaranteed.

## Operator workflow

```bash
# Per-app: customize the preserve-first file freely.
$EDITOR .claude/settings.json     # add project permissions, env vars

# Apply meta-managed policy into preserve-first siblings (idempotent).
# This is the standard scaffolding step for new downstream apps.
bash bootstrap/apply-host-settings.sh --target .

# Preview a downstream's merge plan without writing.
bash bootstrap/apply-host-settings.sh --target . --dry-run --json

# Meta-managed (.aiaast.*) files are NEVER edited downstream.
# Changes go in TEMPLATE/<host>/<settings.aiaast.*> upstream, then sweep:
bash TEMPLATE/_TEMPLATE_FACTORY/run-downstream-additive.sh   # fleet-wide propagation
```

## Apply helper — per-host strategy

`bootstrap/apply-host-settings.sh` walks the manifest and for each `active` adapter:

| Host | Strategy | Outcome |
|------|---------|---------|
| claude | native (no-op) | action=`unchanged` reason=`native_merge` |
| copilot | JSON deep-merge | new keys installed; list values append-only; scalar conflicts → app wins (recorded as `shadowed`) |
| codex | TOML deep-merge (same semantics) | same as JSON |
| gemini | JSON deep-merge | same |
| windsurf | JSON deep-merge | same |
| cursor | JSON deep-merge | same |
| antigravity | JSON deep-merge | same |

**Refusal:** running with `--target TEMPLATE` (the parent template root) refuses with `apply_host_settings_refused: parent_template`. Use `--allow-template` only in smokes.

## Refusal conditions

`check-host-settings-baseline.sh` fails with:

- `file_missing` — declared baseline path absent.
- `parse_error` — JSON/TOML/YAML invalid.
- `marker_missing` — `.aiaast.*` file lacks the `$aiaast` block.
- `preserve_first_sibling_missing` — `.aiaast.*` declares a sibling that wasn't scaffolded.

## Resume points

- **S19a (done):** Claude Code + GitHub Copilot baselines (hybrid pair reference impls).
- **S19b (done):** Codex, Gemini, Windsurf, Cursor baselines + `apply-host-settings.sh` deep-merge helper.
- **S19e (done):** Antigravity CLI/Desktop baseline + isolated tool memory. All 7 primary hosts now `active`.
- **S19c (optional):** per-host launch smoke that boots the host in a sandbox and asserts the meta-policy keys are honored at runtime.
- **S19d (optional):** fleet propagation — preserve-first additive sweep across 31 downstream repos so every app inherits the 6-host baseline; per-app operator runs `bootstrap/apply-host-settings.sh` afterward.
