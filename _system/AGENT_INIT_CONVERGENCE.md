# Agent Init Convergence Contract

This contract maps external initialization workspaces (for example `AgentInits`) into installable AIAST surfaces without leaking maintainer-only context into downstream repos.

## Purpose

- Normalize useful `/init` patterns into installable contracts.
- Keep installable defaults neutral and reusable.
- Preserve comparability across agent adapters.
- Prevent local init experiments from becoming hidden policy forks.

## Source Pattern Mapping

| External Pattern | Installable Target | Status |
| --- | --- | --- |
| `AGENTS.md` shared rules | `AGENTS.md` + `_system/*` contracts | adopted |
| `PROJECT_CONTEXT.md` workspace boundary | `_system/PROJECT_PROFILE.md` + `_system/TEMPLATE_NEUTRALITY_POLICY.md` | adopted |
| `INITIALIZATION_GUIDE.md` onboarding flow | `_system/LOAD_ORDER.md` + `_system/AGENT_DISCOVERY_MATRIX.md` + this file | adopted |
| `AGENT_INIT_LOG.md` handoff ledger | `WHERE_LEFT_OFF.md` + `TODO.md` + `_system/checkpoints/` | adapted |
| `AGENT_TEMPLATE.md` new-agent scaffold | `_system/host-adapter-manifest.json` + placeholder adapter set | adopted |
| conflict-safe additive sectioning (`Additions - Agent - Date`) | `_system/MULTI_AGENT_COORDINATION.md` additive follow-up policy | adopted |
| workspace/target identity gates | `_system/WORKSPACE_AUTHORITY_AND_CONTAINMENT_PROTOCOL.md` + `_system/PROJECT_IDENTITY_AND_SCOPE_PROTOCOL.md` + bootstrap consistency checks | adopted |

## Installable Defaults vs Maintainer-Only State

### Installable by Default

- Stable adapter naming convention.
- Shared-vs-adapter ownership boundaries.
- Additive merge preference for cross-agent continuity docs.
- Placeholder compatibility files for common external agents.

### Maintainer-Only (do not auto-install into app repos)

- Historical multi-agent init transcripts.
- Maintainer planning logs and curation notes.
- Source-repo-only evidence and rollout bookkeeping under `_META_AGENT_SYSTEM/`.

## Required Adapter Names for Cross-Agent Comparability

The installable system maintains these canonical top-level adapter names:

- `CODEX.md`
- `GEMINI.md`
- `CLAUDE.md`
- `CURSOR.md` (placeholder pointer)
- `WINDSURF.md`
- `COPILOT.md` (placeholder pointer)
- `DEEPSEEK.md`
- `AIDER.md` (placeholder pointer)
- `AGENT_ZERO.md` (placeholder pointer)

Additional adapters may be added as long as they are declared in `_system/host-adapter-manifest.json` and reflected in `_system/AGENT_DISCOVERY_MATRIX.md`.

## Preserve-first downstream operations

Rollouts must not silently erase project-specific truth.

For the **master template vs downstream app** distinction, the agent health gate
after installs/updates, and the `_system/TEMPLATE_SYNC_NOTICE.md` contract, read
`DOWNSTREAM_PRESERVATION_AND_SYNC_NOTICE_POLICY.md`.

- **Stateful surfaces (never overwritten by template diff refresh):** paths classified in `bootstrap/lib/aiaast-lib.sh` as `aiaast_is_stateful_path` — for example `TODO.md`, `PLAN.md`, `WHERE_LEFT_OFF.md`, `PRODUCT_BRIEF.md`, `TEST_STRATEGY.md`, `RISK_REGISTER.md`, `_system/PROJECT_PROFILE.md`, and `_system/context/*.md` continuity files.
- **Product-owned runtime seeds:** files under `bootstrap/templates/runtime/` are materialized once into the app tree and then owned by the product; refresh paths must not force-overwrite them (see `aiaast_refresh_onboarding_baseline` commentary on `generate-runtime-foundations.sh`).
- **`migrate-agent-surface-upgrade.sh`:** when `--write` runs `install-missing-files.sh --skip-onboarding-seeds` so suggest/seed passes that would rewrite `PRODUCT_BRIEF.md`, working files, or context bullets are skipped (same contract as `export AIAST_SKIP_ONBOARDING_SEEDS=1` for that refresh only). Only missing template files are copied (rsync `--ignore-existing`), then append-only contract patches and regenerators run.
- **`update-template.sh --refresh-managed`:** still refreshes drifted template-managed files that are not stateful. Operators should commit or use an isolated backup snapshot before broad refreshes on active product branches.
- **Local operator context:** `.ai/` and host-local adapter experiments are normally untracked; keep them out of shared policy merges and do not treat them as authoritative over `AGENTS.md` or `_system/` contracts.

## Merge Protocol

When a new agent-specific rule conflicts with existing shared policy:

1. Preserve shared policy.
2. Add agent-local emphasis only in the adapter or placeholder file.
3. If the rule is broadly applicable, promote it into a shared `_system/` contract.
4. Record any migration or deprecation in release-facing docs.

## Validation Contract

After convergence updates:

1. Regenerate adapters: `bootstrap/generate-host-adapters.sh <repo> --write`.
2. Validate alignment: `bootstrap/check-host-adapter-alignment.sh <repo>`.
3. Validate instruction layer: `bootstrap/validate-instruction-layer.sh <repo>`.
4. Run source template lane: `_TEMPLATE_FACTORY/validate-master-template.sh`.

## Anti-Drift Requirement

If an external init workspace introduces a useful new file type:

- first classify it in `_system/AGENT_SURFACE_TAXONOMY.md`,
- then decide if it belongs in generated adapters, placeholders, or maintainer-only metadata,
- then update `_system/host-adapter-manifest.json` and validators in the same change set.
