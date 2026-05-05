# AIAST Changelog

## Unreleased

- **Enhancement — Downstream preservation + sync notice:** added `_system/DOWNSTREAM_PRESERVATION_AND_SYNC_NOTICE_POLICY.md` (master template vs app repo, preserve-first recap, agent health gate), `_system/TEMPLATE_SYNC_NOTICE.md` baseline, `bootstrap/clear-template-sync-notice.sh`, and `aiaast_emit_template_sync_notice` in `bootstrap/lib/aiaast-lib.sh`. Successful non-dry-run `init-project.sh`, `install-missing-files.sh`, and `update-template.sh` runs now write `_system/TEMPLATE_SYNC_NOTICE.md` with **PENDING_HEALTH_CHECK** and append `_system/history/template-sync-events.jsonl`. `LOAD_ORDER.md`, `CONTEXT_INDEX.md`, `UPGRADE_AND_DRIFT_POLICY.md`, `TEMPLATE_CHANGE_IMPACT_POLICY.md`, and `AGENT_INIT_CONVERGENCE.md` cross-link the policy. Maintainer boundary doc: `_META_AGENT_SYSTEM/DOWNSTREAM_ROLLOUT_PRESERVATION_AND_MASTER_REPO_BOUNDARY.md`.
- **Fix — Template sync history vs managed-file registry:** `_system/history/template-sync-events.jsonl` is classified as stateful/runtime-only, and `_system/history/*` is omitted from `aiaast_print_managed_files` so `check-system-awareness` does not report “Managed file missing from registry” on the same `init-project` run that creates the JSONL append-only log (before a later registry refresh).
- **Fix — Template sync notice vs integrity / doctor:** `_system/TEMPLATE_SYNC_NOTICE.md` is treated as local volatile state for integrity manifest purposes (bootstrap rewrites it after install/update), so `verify-integrity` no longer false-fails on fresh downstream repos. **`system-doctor.sh`:** corrected `check-swarm-fleet` control flow so a failed swarm check sets `failed=1` without being masked by the `|| failed=1` idiom inside the `if` condition.

- **Enhancement — Preserve-first agent-surface migration:** `migrate-agent-surface-upgrade.sh --write` runs `install-missing-files.sh --skip-onboarding-seeds`, and `aiaast_refresh_onboarding_baseline` honors `AIAST_SKIP_ONBOARDING_SEEDS=1` by skipping suggest/seed passes so `PRODUCT_BRIEF.md`, working files, and `_system/context` bullets are not bulk-rewritten during additive file installs. Operators can pass `--skip-onboarding-seeds` on any `install-missing-files.sh` invocation for the same effect. Documented in `_system/AGENT_INIT_CONVERGENCE.md` and `bootstrap/update-template.sh` usage text for `--refresh-managed` snapshot expectations.

- **Enhancement — Contract sync command:** added
  `bootstrap/sync-metasystem-contracts.sh` to run adapter generation, system registry/profile regeneration, integrity generation, and core validation checks in one deterministic flow.
- **Enhancement — Downstream migration assistant:** added
  `bootstrap/migrate-agent-surface-upgrade.sh` with `--dry-run` and `--write`
  modes to roll out dual-metasystem agent-surface upgrades to existing
  downstream repos.
- **Enhancement — Parity and quality gates:** added
  `_TEMPLATE_FACTORY/check-aiast-mos-parity.sh` and
  `_TEMPLATE_FACTORY/check-metasystem-quality-gate.sh`; both are now integrated
  into `_TEMPLATE_FACTORY/validate-master-template.sh`.
- **Enhancement — Adapter alias lifecycle enforcement:** extended
  `_system/host-adapter-manifest.json` `deprecated_aliases` entries with
  `target`, `deprecated_since`, `remove_after`, and `migration_doc`, and
  updated validators to fail on expired alias windows.
- **Enhancement — Dual metasystem unification:** added installable adapter governance and convergence contracts:
  - `_system/AGENT_SURFACE_TAXONOMY.md`
  - `_system/AGENT_INIT_CONVERGENCE.md`
  - `_system/OPERATOR_PROMPTING_PLAYBOOK.md`
- **Enhancement — Adapter parity placeholders:** added `CURSOR.md`, `COPILOT.md`, `AIDER.md`, and `AGENT_ZERO.md` as thin compatibility pointer files for scaffold comparability across mixed agent ecosystems.
- **Enhancement — Validation lane hardening:** added `bootstrap/check-agent-surface-integrity.sh`, integrated it into `_TEMPLATE_FACTORY/validate-master-template.sh`, and extended host-adapter alignment checks to enforce required placeholder presence and taxonomy/convergence references.
- **Enhancement — Meta-of-meta governance:** added `_META_AGENT_SYSTEM/META_GOVERNANCE_FRAMEWORK.md` for proposal lifecycle, compatibility tiers, and evidence-backed release gates.
- **Enhancement — MOS parity crosswalk:** added `MOS_TEMPLATE/meta_system/META_AGENT_SURFACE_CROSSWALK.md` and wired MOS host-adapter policy/load/context docs to the crosswalk.

- **Fix — `bootstrap/lib/aiaast-lib.sh`:** `aiaast_refresh_onboarding_baseline`
  no longer propagates its `force` parameter to
  `generate-runtime-foundations.sh`. Runtime foundation templates under
  `bootstrap/templates/runtime/` are product-owned seeds (e.g.
  `ops/install/install.sh`, `ops/install/lib/runtime-foundation.sh`,
  `ops/compose/compose.yml`, `ops/env/.env.example`,
  `ops/install/lib/port_allocator.py`) that are copied into a downstream
  on first install and then customized by the app. Before this fix,
  `update-template.sh --refresh-managed` passed `REFRESH_MANAGED=1` as
  `force` all the way down to `generate-runtime-foundations.sh --force`,
  which silently overwrote the downstream's product-customized runtime
  seeds with the template's generic stubs. This was discovered during the
  first `1.23.0` replay to a production-scale repo, where ~989 lines of M1
  host-install work in `runtime-foundation.sh` were erased; the product
  content was restored from the pre-refresh commit. See maintainer proof
  evidence for the forensic trail. **This fix is committed on source `main`
  but is not yet published under a tag; the next release (whether `1.23.1` or
  whichever label a maintainer chooses) should ship it.**

## 1.23.0 (2026-04-14)

**Git tag:** `v1.23.0` (annotated tag on the AIAST source repository `main` branch).

### Cross-agent checkpointing capability

- **`bootstrap/write-checkpoint.sh`:** new agent-neutral writer of mid-session
  resume checkpoints. Any agent (Claude, Codex, Cursor, Gemini, Windsurf,
  DeepSeek, Cline, Continue, Aider, PearAI, local models, or a human) can
  persist the current phase, completed steps, in-progress step, ordered next
  actions, blockers, resume files, resume command, and validation state into
  `_system/checkpoints/LATEST.json` + `LATEST.md` with an append-only history
  under `_system/checkpoints/history/`. Writes are atomic (tempfile + rename).
  Supports five checkpoint kinds: `session-start`, `mid-task`, `handoff`,
  `rate-limit-save`, `milestone`. Accepts `--from-json` for pre-built payloads
  with flag overrides layered on top. Zero new runtime dependencies beyond
  the `bash` + `python3` already required by the rest of the bootstrap layer.
- **`bootstrap/resume-from-checkpoint.sh`:** new concise resume-briefing reader.
  Emits a plain-text human briefing by default, JSON or Markdown on request,
  and can list every historical checkpoint. Exit codes distinguish "no
  checkpoint" (`3`) from "malformed checkpoint" (`4`) so scripts can branch
  cleanly.
- **`_system/CHECKPOINT_PROTOCOL.md`:** fully rewritten for mid-session
  semantics (not only session-end). Documents the five checkpoint kinds,
  required fields, writing and reading examples, file layout, rules
  (no secrets, honest validation, specific resume files), and the
  relationship between checkpoints, `WHERE_LEFT_OFF.md`, and
  `HANDOFF_PROTOCOL.md`.
- **`_system/checkpoints/README.md`:** seed doc describing the checkpoint
  directory layout and the rules for every downstream install.
- **Startup wiring:** `_system/CONTEXT_INDEX.md`, `_system/LOAD_ORDER.md`,
  `_system/MASTER_SYSTEM_PROMPT.md`, and `_system/SYSTEM_AWARENESS_PROTOCOL.md`
  now instruct every agent to run `bootstrap/resume-from-checkpoint.sh` on
  cold start, to write a checkpoint before stopping for any reason, and to
  persist `rate-limit-save` checkpoints before any command that could
  exhaust the remaining token/time budget.
- **`aiaast-capabilities.json`:** new `cross_agent_checkpointing` capability
  flag and `checkpoint_protocol` / `checkpoint_writer` / `checkpoint_reader` /
  `checkpoints_directory` markers.

### Downstream self-healing for `bootstrap/update-template.sh`

- **`bootstrap/update-template.sh`:** added a re-exec guard that detects drift
  between the installed copy of the script and the source template copy.
  When `--refresh-managed` is active and the two differ, the script copies
  the source version to a tempfile and re-execs from there before touching
  any managed files, preventing the bash parser corruption that previously
  occurred when the refresh loop rewrote the currently-executing script.
  Guarded by `AIAST_UPDATE_REEXEC` to prevent infinite re-exec loops, with
  an `EXIT` trap that cleans up the tempfile. Downstreams running pre-fix
  installed copies should run the **source** template's script directly
  once to clear the hazard; subsequent updates use the installed copy
  with the guard in place.

### Release process

- **Version markers:** `_system/.template-version`, `_system/.template-install.json`,
  `_system/aiaast-capabilities.json`, and `AIAST_VERSION.md` all bumped to
  `1.23.0` — minor bump because the checkpointing surfaces and scripts are
  net-new additive capability.
- **Validation:** `_TEMPLATE_FACTORY/run-maintainer-lane.sh` →
  `maintainer_lane_ok`, `_TEMPLATE_FACTORY/run-automation-lane.sh` →
  `automation_lane_ok`, `bootstrap/system-doctor.sh TEMPLATE --strict` → all
  16 checks green, `bootstrap/check-system-awareness.sh TEMPLATE` →
  `system_awareness_ok`.

## 1.22.1 (2026-04-12)

**Git tag:** `v1.22.1` (annotated tag on the AIAST source repository `main` branch).

### Downstream sync and integrity corrections

- **`bootstrap/update-template.sh`:** now repairs managed-file mode drift even
  when downstream file contents already match the source template, so `+x`
  bootstrap surfaces recover during refresh instead of staying silently wrong.
- **`bootstrap/lib/aiaast-lib.sh`:** integrity manifests now enumerate the
  managed installable surface instead of raw `find` output, eliminating
  transient runtime and bytecode noise from the canonical manifest while adding
  managed roots such as `distribution/`, `docs/`, `notes/`, `.credits-hidden`,
  `LICENSE`, and `NOTICE`.

### Proof-backed release closure

- **`CandleCompass` downstream proof:** the first `1.22.0` replay exposed an
  installed-doc boundary leak around absolute maintainer source-clone paths;
  after sanitizing those docs and replaying the fixed source template, strict
  validation and `system-doctor.sh` both passed.
- **`DOWNSTREAM_PROOF_PLAYBOOK.md`:** now documents the forbidden
  absolute-master-template-path failure mode and the required neutralized
  wording for installed continuity docs.

### Version alignment

- Patch release so installable **semver** (`AIAST_VERSION.md`,
  `_system/.template-version`, JSON markers, and plugin manifests
  `aiast_min_version`) matches the proof-backed source tag **`v1.22.1`**.

## 1.22.0 (2026-04-12)

### Governance hardening

- **`READ_BUNDLES.md`:** task-scoped bundle entrypoints so agents can load the smallest useful AIAST context instead of defaulting to the full load order.
- **`TEMPLATE_CHANGE_IMPACT_POLICY.md`:** high-risk template change classes and required follow-through for precedence, host emission, repair, install, update, and validation surfaces.
- **`SELF_HEALING_BOUNDARY.md`:** explicit separation between safe automatic repair and unsafe repair that requires review.
- **`VERSION_SENSITIVE_RESEARCH_PROTOCOL.md`:** installable research-discipline contract for frameworks, packages, installers, platforms, APIs, and host tools that may change over time.

### Maintainer promotion discipline

- **Maintainer-only learning loop and promotion doctrine:** the master-repo meta workspace now governs how strong downstream patterns can be harvested back into AIAST without leaking app-specific truth.
- **Maintainer-only enhancement review packet:** preservation ledger, donor review, and AIAST-vs-SACST import map grounded in the full local repo audit plus the donor read of `/home/whyte/.MyAdminZ/_SYS_AGENT_CORE_TEMPLATE`.
- **`_TEMPLATE_FACTORY/check-template-impact.sh`** and **`check-promotion-readiness.sh`:** new factory checks for change-impact classification, follow-through requirements, donor provenance, and promotion gating.

### Validation and generated-surface alignment

- **`INSTRUCTION_PRECEDENCE_CONTRACT.md`**, **`instruction-precedence.json`**, **`PROMPT_EMISSION_CONTRACT.md`**, **`HOST_BUNDLE_CONTRACT.md`**, **`LOAD_ORDER.md`**, and **`REPO_OPERATING_PROFILE.*`:** aligned around bundle-aware loading, exact consistency surfaces, and stricter governance cross-references.
- **Validators and generators:** `detect-instruction-conflicts.sh`, `validate-instruction-layer.sh`, `check-system-awareness.sh`, `generate-operating-profile.sh`, and `system-doctor.sh` now recognize the new governance surfaces directly.
- **Generated artifacts:** host adapters, `_system/KEY.md`, `_system/SYSTEM_REGISTRY.json`, `_system/repo-operating-profile.json`, and `_system/INTEGRITY_MANIFEST.sha256` regenerated for the 1.22.0 surface.
- **Proof:** `_TEMPLATE_FACTORY/run-maintainer-lane.sh` and `_TEMPLATE_FACTORY/run-automation-lane.sh` passed on 2026-04-12, including strict source validation, installed-repo smoke, update-template smoke, blueprint, host-bundle, packaging, runtime-foundation, campaign, and live-host proofs.

## 1.21.1 (2026-04-06)

### Context efficiency

- **Input prose compression (opt-in):** `bootstrap/compress-context-file.sh`, `/compress-context`, `compress-context-input` skill, `CONTEXT_BUDGET_STRATEGY.md` subsection (mechanics + invocation), factory-vendored `caveman-compress` under `_TEMPLATE_FACTORY/third_party/`. Tiered loading remains primary; only `docs/` and `notes/` prose paths are allowlisted.
- **`docs/README.md`**, **`notes/README.md`**, and **`TROUBLESHOOTING.md`** — symmetry for optional longform trees; FAQ for “compress-context-file refuses my path”.

### Documentation

- **`UPGRADE_AND_DRIFT_POLICY.md`:** **Pinning the source template (release tags)** — use `git fetch origin --tags` and checkout an annotated tag (for example `v1.21.0` or `v1.21.1`) in the master clone before passing `TEMPLATE/` to `bootstrap/update-template.sh --source` for reproducible drift checks.
- **`GIT_REMOTE_AND_SYNC_PROTOCOL.md`:** **Release tags** section — cross-links upgrade policy and `RELEASE_NOTES.md` / `AIAST_CHANGELOG.md`.

### Version alignment

- Patch release so installable **semver** (`AIAST_VERSION.md`, `.template-version`, JSON markers) matches the **documented** git-tag workflow; tag **`v1.21.1`** on the source repo marks this tree.

## 1.21.0 (2026-04-06)

**Git tag:** `v1.21.0` (annotated tag on the AIAST source repository `main` branch).

### GitHub merge discipline

- **`.github/pull_request_template.md`** — PR checklist (validation, secrets, AIAST contracts, hooks).
- **`.github/ISSUE_TEMPLATE/`** — `config.yml`, `bug_report.md`, `feature_request.md` for consistent triage.
- **`HOOK_AND_ORCHESTRATION_INDEX.md`** — extended with PR/issue template row; `CONTEXT_INDEX.md` links to `.github/` templates.

### Platform expansion (M16) and installable contracts

- **`M16_PLATFORM_PRODUCT_EXPANSION.md`** — bounded multi-surface expansion and hardening; **`PROMPTS_INDEX.md`** lists M15/M16.
- **Neutral app-fill placeholders:** `DELIVERY_GATES.md`, `AI_RULES.md`, `REPO_CONVENTIONS.md`, `SECURITY_BASELINE.md`.
- **`REQUEST_ALIGNMENT_PROTOCOL.md`** — risk-aware clarification; wired into `MASTER_SYSTEM_PROMPT.md` and discovery docs.

### Autonomous guardrails and scheduling

- **`bootstrap/run-autonomous-guardrails.sh`**, **`bootstrap/install-autonomous-guardrails.sh`** — recurring checks; installer **`--dry-run`**; cron fallback uses valid multi-hour patterns when the minute field cannot express the interval.
- **`_system/automation/.gitignore`**, **`AUTONOMOUS_GUARDRAILS_PROTOCOL.md`** — runtime log hygiene and operator workflow.

### Delivery-gate alignment and troubleshooting

- **`bootstrap/check-delivery-gate-alignment.sh`** — enforced via **`validate-system.sh`** and **`system-doctor.sh`** so contracts stay discoverable in `CONTEXT_INDEX.md`, `LOAD_ORDER.md`, and `MASTER_SYSTEM_PROMPT.md`.
- **`VALIDATION_GATES.md`** — impact mapping when editing gates or contracts; **`DELIVERY_GATES.md`** — automated wiring section; **`AUTONOMOUS_GUARDRAILS_PROTOCOL.md`** — quick-mode note; **`TROUBLESHOOTING.md`** — remediation for alignment failures.

### Documentation (carried forward from pre-release)

- **`HOOK_AND_ORCHESTRATION_INDEX.md`** — map of build-out hooks (Cursor rules/commands/skills/agents, plugins, validation doctors, GitHub/CI, MCP) and required companion files. **GitHub / CI steward** role in `AGENT_ROLE_CATALOG.md`; `.cursor/agents/github-ops.md`, `.cursor/commands/github-session.md`; Copilot and `AGENTS.md` cross-links; `MULTI_AGENT_COORDINATION.md` and `AGENT_DISCOVERY_MATRIX.md` updates.
- **`AGENT_INSTALLER_AND_HOST_VALIDATION_PROTOCOL.md`** — binding agent rules: scaffold installers early after first launchable build; production-like host testing (desktop integration where applicable); robust install/repair/uninstall; governed secure ports and DB/dependency setup; re-verify launch/render after large workloads. Wired into `AGENTS.md`, `MASTER_SYSTEM_PROMPT.md`, `LOAD_ORDER.md`, `VALIDATION_GATES.md`, `EXECUTION_PROTOCOL.md`, `ports/PORT_POLICY.md`, `CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md`, `M6_INSTALL_AND_DISTRIBUTION.md`, and `CONTEXT_INDEX.md`.
- `bootstrap/templates/runtime/ops/compose/compose.yml` — comment reminding operators to assign a **unique** `APP_PORT` per repo when running multiple stacks on one machine (see `_system/ports/PORT_POLICY.md`).

### Working files

- Refreshed `PLAN.md`, `FIXME.md`, `RISK_REGISTER.md`, `TEST_STRATEGY.md`, `RELEASE_NOTES.md`, `_system/context/CURRENT_STATUS.md`, `_system/context/DECISIONS.md` (baseline content + 2026-04-06 review) to support `check-working-file-staleness.sh` and clearer downstream defaults.

### Maintainer (master repo only)

- Root `.github/pull_request_template.md` and `.github/ISSUE_TEMPLATE/` for AIAST layer-specific PR/issue discipline.

## 1.20.0 (2026-04-05)

### Plugin Contract V2 & Agent-Capability Matching

- **Plugin Contract V2:** Formalized richer `capabilities` and new lifecycle hooks (`bootstrap.pre_flight`, `validation.report`).
- **Capability Discovery:** Enhanced `discover-plugins.sh` to automatically generate `_system/CAPABILITY_MATRIX.json`.
- **Agent Matchmaking:** Updated `AGENT_ROLE_CATALOG.md` to map agent roles (e.g., `fleet_secops`) to native plugin capabilities.
- **Diagnostic Visibility:** Integrated capability matrix display into `system-doctor.sh`.
- **Core Plugins:** Updated `security-scan`, `ci-integration`, and `observability-setup` to align with the V2 contract.

## 1.19.7 (2026-04-05)

### Resilient Swarm Architecture & Anti-Drift SSoT

- **Swarm Fleet Operations:** Introduced Task-Isolated AI Branching (TIA-Branching) for parallel agent work.
- **Git Swarm Manager:** New `bootstrap/git-swarm-manager.sh` for collision-free commits and automated push/squash.
- **Anti-Drift SSoT:** Enforced `TEMPLATE/_system/` as the single source of truth; banned global IDE mutations.
- **Agent Hook Parity:** Unified adapters for Cursor, Windsurf, Claude/Cline, Continue, and Copilot.
- **Resilience & Repair:** New `bootstrap/repair-swarm-integrity.sh` and `AUTH_RECOVERY_PROTOCOL.md` for self-healing.
- **System Doctor Integration:** Added `check-swarm-fleet.sh` to the standard diagnostic suite.
- **MCP Fleet:** Defined core MCP servers and added `validate-mcp-health.sh` for connectivity and re-auth.

## 1.19.6 (2026-04-05)

### Changed
- `GIT_REMOTE_AND_SYNC_PROTOCOL.md` — **Non-negotiable priority**: Git sync treated as blocking work; session start `git fetch`, end-of-session commit + push; `.git` ownership repair; hooks / `--no-verify` policy.
- `AGENTS.md` (installable + master root) — explicit **Git and remotes** section; master repo commit/push and `whyte`-only expectations.

### Meta (master repo only)
- `context/OWNER_GIT_REMOTES.md` — agent expectations: Git tasks non-negotiable when work should survive.

## 1.19.5 - 2026-04-05

### Added
- `_system/GIT_REMOTE_AND_SYNC_PROTOCOL.md` — GitHub remotes, **SSH** transport, fetch/pull/push sync discipline, empty-remote bootstrap, auth failure handling; SavigeSystemZ operator profile (`SavageO13` / `SavigeSystemZ`, Michael Spaulding, `mtspaulding87@gmail.com`); **run Git and SSH as UNIX user `whyte`, not `root`** (keys and agent are user-scoped).

### Changed
- `LOAD_ORDER.md` — Tier 2 includes `GIT_REMOTE_AND_SYNC_PROTOCOL.md`; Tier 3 and later sections renumbered.
- `CONTEXT_INDEX.md` — discovery entry for the Git remote and sync protocol.
- `bootstrap/check-network-bindings.sh` — skip `.mypy_cache` / `.ruff_cache` / `.pytest_cache` and vendored `_AI_AGENT_SYSTEM/` when scanning for wildcard binds (reduces false positives in real app trees).

### Meta (master repo only)
- `context/OWNER_GIT_REMOTES.md` — maintainer-only mirror of org layout, identity, and **`whyte`-only Git/SSH** rule.
- `KEY.md`, `META_SYSTEM_INTERCONNECT_INDEX.md`, `WHERE_LEFT_OFF.md`, `context/CURRENT_STATUS.md` — continuity and cross-links.

## 1.19.4 - 2026-04-05

### Added
- `_system/AUTH_AND_ONBOARDING_PATTERNS.md` — optional vs gated auth, progressive trust, env-only dev seed admins (no credentials in git)

### Changed
- `MODERN_UI_PATTERNS.md` — navigation deduplication (avoid redundant menus/buttons on the same surface)
- `SECURITY_HARDENING_CONTRACT.md` — explicit ban on default accounts in source; pointer to auth patterns
- `bootstrap/templates/runtime/ops/env/.env.example` — commented `SEED_DEV_ADMIN` / `SEED_ADMIN_*` placeholders
- `CONTEXT_INDEX.md`, `LOAD_ORDER.md`, `AGENTS.md`, `emit-tiered-context.sh` Tier B — wire new contract

## 1.19.3 - 2026-04-05

### Added
- `bootstrap/emit-auxiliary-brief.sh` — CLI to print a frozen auxiliary brief (flags + env overrides)

### Changed
- `SUB_AGENT_HOST_DELEGATION.md` — scope split recipes, primary merge checklist, anti-patterns, bootstrap usage example
- `HANDOFF_PROTOCOL.md` — auxiliary-to-primary handback expectations
- `M9_MULTI_AGENT_CONTINUITY.md` — load sub-agent delegation when planning parallel host sessions
- `check-agent-orchestration.sh` — M9 pack must reference sub-agent delegation
- `60-composer-orchestration.mdc`, `PROMPTS_INDEX.md`, `CONTEXT_INDEX.md`, `bootstrap/README.md` — document the emitter

## 1.19.2 - 2026-04-05

### Added
- `SUB_AGENT_HOST_DELEGATION.md` — copy-paste **auxiliary brief template** for parallel host sessions

### Changed
- `EXECUTION_PROTOCOL.md` — decision rules reference sub-agent delegation when using separate host tools
- `bootstrap/emit-tiered-context.sh` — Tier **B** context list now includes `SUB_AGENT_HOST_DELEGATION.md`

### Meta (master repo only)
- `META_SYSTEM_INTERCONNECT_INDEX.md` — index rows for `DEFERRED_USER_REMINDERS.md` and the installable sub-agent contract
- `DEFERRED_USER_REMINDERS.md` — schedule note for next-prompt execution of downstream follow-ups

## 1.19.1 - 2026-04-05

### Added
- `_system/SUB_AGENT_HOST_DELEGATION.md` — optional parallel host CLI / auxiliary sessions (honest limits: no auto-spawn MCP), primary takeover on failure
- `_META_AGENT_SYSTEM/DEFERRED_USER_REMINDERS.md` — maintainer-only deferred follow-ups the user asked to surface after ~two future prompts

### Changed
- `CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md` — **minimum launch milestone**: scaffold installers/distribution once the app is first launchable for host dogfooding
- `PROMPT_SYSTEM_BUILD_STANDARD.md`, `M10_GREENFIELD_BOOTSTRAP.md` — align greenfield work with early installer scaffolds
- `MULTI_AGENT_COORDINATION.md`, `AGENTS.md`, `.cursor/rules/60-composer-orchestration.mdc` — cross-link sub-agent delegation rules
- `CONTEXT_INDEX.md`, `LOAD_ORDER.md` — index new contract

## 1.19.0 - 2026-04-04

### Added — Cross-platform distribution and Composer overlays
- `_system/CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md` — shipped-app installer contract (multi-OS layout, operator menu, port governance, hardening expectations) distinct from AIAST lifecycle `INSTALLER_AND_UPGRADE_CONTRACT.md`
- `bootstrap/templates/runtime/distribution/**` — generated `distribution/` tree with `platforms/linux|windows|macos|android|ios` READMEs and a Windows `Install.ps1` scaffold
- `.cursor/rules/60-composer-orchestration.mdc`, `.cursor/commands/composer-session.md`, `.cursor/agents/composer-lead.md` — Composer-oriented orchestration overlays

### Changed
- `_system/CONTEXT_INDEX.md`, `_system/LOAD_ORDER.md`, `_system/PROMPT_SYSTEM_BUILD_STANDARD.md`, `_system/prompt-packs/M6_INSTALL_AND_DISTRIBUTION.md`, and `bootstrap/check-runtime-foundations.sh` now reference `distribution/` and the new standard
- `bootstrap/validate-system.sh` requires the new runtime template paths

### Meta (master repo only)
- `_META_AGENT_SYSTEM/META_SYSTEM_INTERCONNECT_INDEX.md` — maintainer layer awareness graph and refresh rules

## 1.17.0 - 2026-04-03

### Added — Installer Integrity and Smart Scaffold Entry
- `bootstrap/scaffold-system.sh` — unified smart entrypoint that auto-detects target state and routes to first install, additive backfill, or update flow.
- `_system/INSTALLER_AND_UPGRADE_CONTRACT.md` — explicit contract for install, update, repair, and heal behavior plus state-preservation guarantees.

### Changed — Bootstrap UX and Drift Resistance
- `init-project.sh`, `install-missing-files.sh`, and `wizard.sh` now prompt for target path when run interactively without arguments.
- `validate-system.sh`, `check-system-awareness.sh`, and `validate-instruction-layer.sh` now enforce the installer contract and smart scaffold surfaces.
- `bootstrap/README.md`, `_system/QUICKSTART.md`, `_system/LOAD_ORDER.md`, `_system/CONTEXT_INDEX.md`, and `_system/UPGRADE_AND_DRIFT_POLICY.md` now cross-link installer behavior and customization flow.

### Changed — Neutrality and Product-Safe Guidance
- `_system/CURSOR_AND_MULTI_HOST.md` now uses generic multi-repo examples instead of environment-specific names.
- `_system/SECURITY_HARDENING_CONTRACT.md` privilege-separation example is now app-neutral.
- `_system/PROJECT_PROFILE.md` now includes post-scaffold customization instructions for app-specific truth.

### Fixed — Factory Lane Reliability
- `_TEMPLATE_FACTORY/GOLDEN_EXAMPLES/REVIEW_NOTES.md` now includes required review sections for all high-scoring non-selected repos.
- `validate-system.sh` absolute-path leak detection now excludes `.git` internals to avoid false positives in strict update smoke.
- `_TEMPLATE_FACTORY/smoke-live-host-clis.sh` treats Cursor root-only `--no-sandbox` refusal as a soft-skip condition.

## 1.16.0 - 2026-03-28

### Added — Gemini "Infinite" Context (Tier S) and Whole-Repo Analysis
- `_system/prompt-packs/M15_WHOLE_REPO_ANALYSIS.md` — new prompt pack for Tier S agents (1M+ tokens) focused on deep architectural reviews, system-wide consistency audits, and comprehensive impact analysis
- `Tier S: Infinite (1M+ tokens)` added to `CONTEXT_BUDGET_STRATEGY.md` and `agent-performance-profiles.json`, elevating Gemini 2.5 Pro and Flash to this elite context tier
- Gemini-optimized expectations in `GEMINI.md` (via `host-adapter-manifest.json`), including mandates for multimodal verification, deep 'Chain of Thought' reasoning, and Tier S architectural analysis

### Changed — Agent Capability and Execution Guidance
- `AGENT_PERFORMANCE_GUIDE.md` now includes Tier S and whole-repo analysis as a primary task-to-model mapping
- `AGENT_DISCOVERY_MATRIX.md` updated to reflect Gemini's best use as a whole-repo synthesizer and architectural auditor
- `EXECUTION_PROTOCOL.md` now carries explicit guidance for Tier S agents, including cross-referencing runtime code against the entire `_system/` layer to detect drift and using multimodal inputs for UI/UX fidelity

### Changed — Regenerated Adapters and System Assets
- All 17 tool-specific adapters (CLAUDE.md, CODEX.md, GEMINI.md, etc.) regenerated to include the M15 prompt pack in their domain-optional load paths
- `SYSTEM_REGISTRY.json` and `INTEGRITY_MANIFEST.sha256` updated to include the M15 prompt pack and updated version markers
- `KEY.md` and `REPO_OPERATING_PROFILE.md` regenerated to reflect the expanded system surface (343 managed files)

## 1.15.0 - 2026-03-28

### Added — Handoff Governance and Evidence Validation
- `_system/HANDOFF_PROTOCOL.md` — formalized quality requirements for
  agent-to-agent handoffs with required fields, evidence standard, and
  anti-pattern guidance
- `bootstrap/check-evidence-quality.sh` — scans WHERE_LEFT_OFF.md,
  CURRENT_STATUS.md, and RELEASE_NOTES.md for ungrounded claims (e.g.,
  "all tests pass" without command evidence)
- `bootstrap/check-working-file-staleness.sh` — detects stale handoff
  and planning files by comparing git timestamps, embedded dates, and
  cross-checking WHERE_LEFT_OFF.md phase against PLAN.md objective
- `bootstrap/check-bootstrap-permissions.sh` — validates all bootstrap/*.sh
  scripts are executable, with `--fix` mode for automatic repair

### Changed — Enhanced Working File Templates
- `WHERE_LEFT_OFF.md` template now includes required-field guidance,
  concrete good/bad examples, and references to the handoff protocol
  and evidence quality checker
- `TODO.md` template now includes priority signals (CRITICAL/HIGH/MEDIUM/LOW)
  with definitions and a Completed section for session-end tracking
- `EXECUTION_PROTOCOL.md` Stage 5 now references HANDOFF_PROTOCOL.md and
  the evidence quality checker
- `VALIDATION_GATES.md` evidence standard now references the handoff protocol
  and both new validation scripts
- `HALLUCINATION_DEFENSE_PROTOCOL.md` now lists the evidence quality and
  staleness detection commands
- `CONTEXT_INDEX.md` now lists the handoff protocol and all 3 new scripts
- `LOAD_ORDER.md` Tier 2 now includes HANDOFF_PROTOCOL.md; Tier 3 now
  includes the 3 new bootstrap scripts

### Changed — System Doctor Expansion
- `system-doctor.sh` now runs 16 checks (was 13), integrating
  check-bootstrap-permissions, check-evidence-quality, and
  check-working-file-staleness as warning-level checks

### Fixed — Bootstrap Script Permissions
- Added missing execute permission on 3 scripts: apply-starter-blueprint.sh,
  check-host-bundle.sh, emit-host-bundle.sh (discovered by the new
  permissions checker)

## 1.14.0 - 2026-03-27

### Added — Cross-Agent Adapter Expansion (M1)
- 6 new agent adapters: DEEPSEEK.md, .aider.conf.yml, .continuerules, .clinerules, PEARAI.md, LOCAL_MODELS.md
- `render_aider()` function in generate-host-adapters.sh for YAML adapter output
- Updated AGENT_DISCOVERY_MATRIX.md and MULTI_AGENT_COORDINATION.md with all new agents

### Added — Context-Budget-Aware Loading (M2)
- CONTEXT_BUDGET_STRATEGY.md — 4-tier model (A/B/C/D) keyed by context window
- context-budget-profiles.json — machine-readable tier assignments for 21 model families
- emit-tiered-context.sh — emits tier-appropriate context load with --model fuzzy matching

### Added — Golden Examples Expansion (M3)
- 8 new pattern guides: microservices, event-driven/CQRS, serverless/edge, realtime collaboration, data pipeline/ML, error handling, testing, code snippets
- Updated PATTERN_INDEX.md and golden-example-manifest.json

### Added — Plugin Framework (M4)
- Expanded PLUGIN_CONTRACT.md from 33 to ~120 lines with full schema and 12 hook points
- validate-plugin.sh and discover-plugins.sh scripts
- 3 reference plugins: security-scan, ci-integration, observability-setup

### Added — Self-Healing & Environment Validation (M5)
- ENVIRONMENT_VALIDATION_CONTRACT.md — scope and rules for environment checks
- check-environment.sh — validates CLI tools, ports, disk, env files
- generate-diagnostic-report.sh — aggregated health report (--json)
- health-history.json and report-health-trends.sh — append-only trend tracking
- system-doctor.sh gains --report and --record flags

### Added — Documentation & Discoverability (M6)
- QUICKSTART.md — 5-minute onboarding guide
- ARCHITECTURE_DIAGRAM.md — ASCII box diagrams of system architecture
- TROUBLESHOOTING.md — 13 symptom-based FAQ entries
- MIGRATION_GUIDE.md — migration paths from no-system, Cursor-only, custom CLAUDE.md, other frameworks

### Added — Interactive Wizard & UX (M7)
- wizard.sh — guided interactive setup (--non-interactive, --dry-run)
- upgrade-assistant.sh — interactive upgrade guidance with version diff and breaking change warnings
- Visual progress helpers in aiaast-lib.sh (section_header, progress_start/step/done/warn/fail)

### Added — Security Automation (M8)
- run-sast.sh — dispatches to semgrep, bandit, eslint-security, gosec
- check-supply-chain.sh — npm/pip/cargo/go audit with license checking
- scan-container.sh — trivy/grype + static Dockerfile lint
- check-network-bindings.sh — detects 0.0.0.0/:: wildcard violations

### Added — Novel Enhancements (M9)
- AGENT_PERFORMANCE_GUIDE.md — model capability dimensions and task routing
- agent-performance-profiles.json — ratings for 19 model families
- PROMPT_EFFECTIVENESS_TRACKING.md — protocol for measuring prompt pack success
- context/prompt-usage-log.json — effectiveness tracking log
- track-semantic-changes.sh — classifies git diffs as structural/contractual/cosmetic/behavioral

### Changed
- validate-system.sh now requires all new files (total required files increased)
- CONTEXT_INDEX.md updated with all new sections and files
- LOAD_ORDER.md updated with onboarding section and context budget guidance
- README.md updated with all 12 agent adapters and QUICKSTART link
- SYSTEM_REGISTRY.json and INTEGRITY_MANIFEST.sha256 regenerated

## 1.13.7 - 2026-03-26

### Fixed

- the Flutter Android blueprint guidance now explicitly tells agents to run
  `flutter create --platforms=android .` around the copied minimal foundation
  before expecting Flutter analyze, test, or APK build commands to work
- the shipped mobile runtime READMEs and mobile guide now say the same thing in
  installable repo-local terms, so downstream agents no longer have to infer
  the missing Flutter/Gradle project-generation step from a sparse scaffold
- `_TEMPLATE_FACTORY/smoke-test-app-campaign.sh` now includes the mobile repo in
  its wrapper proof and asserts that the copied mobile README and blueprint both
  carry the downstream-proven bootstrap step

## 1.13.6 - 2026-03-25

### Changed

- `bootstrap/validate-system.sh` now also checks
  `_system/instruction-precedence.json.template_version` so stale precedence
  manifests cannot silently drift from the rest of the version surfaces
- the FastAPI and Python CLI starter-blueprint guidance now tells agents to use
  a `src/` layout or explicit package discovery in `pyproject.toml` inside
  scaffolded AIAST repos instead of relying on flat setuptools auto-discovery

## 1.13.5 - 2026-03-25

### Added

- `bootstrap/generate-system-key.sh` so installed repos can regenerate an
  exhaustive agent-facing key for the full AIAST-managed file set
- `_system/KEY.md` as the installable exhaustive file-by-file map of the AIAST
  surface, including what each file is for and when it should be used

### Changed

- installable startup and discovery docs now point agents at `_system/KEY.md`
  when they need full coverage instead of a shorter index view
- strict validation and source-template automation now treat the generated key
  as a first-class required surface alongside the registry and operating
  profile

### Fixed

- `bootstrap/generate-system-key.sh` now resolves relative target paths
  correctly so `bootstrap/generate-system-key.sh . --write` writes to the real
  repo instead of nesting an extra relative path under the target root

## 1.13.4 - 2026-03-25

### Fixed

- the shipped Flatpak manifest templates now use the repo root as their source
  dir when the manifest lives under `packaging/`, so real `flatpak-builder`
  runs can see repo-root artifacts like `dist/<app>` instead of failing during
  install
- packaging docs now state that the Flatpak source dir must stay rooted at
  `..` for repo-root build outputs to remain visible during packaging
- `_TEMPLATE_FACTORY/smoke-packaging-builders.sh` is now a real host-validated
  gate because the required Flatpak runtime is installed locally and the shipped
  manifest no longer points at the wrong build context

## 1.13.3 - 2026-03-25

### Fixed

- `bootstrap/update-template.sh` now always refreshes the installed version and contract-manifest surfaces that generated upgrade metadata depends on, and lifecycle metadata now stores a neutral template-source label instead of a machine-local absolute path, so additive upgrades stop reporting stale versions without leaking maintainer paths into installed repos
- strict template updates now validate against the canonical source-template validator chain instead of trusting drifted target-side validator copies, so preserved older validation scripts can no longer mask an invalid instruction layer during upgrade
- `_TEMPLATE_FACTORY/validate-master-template.sh` now exercises an upgrade regression where a downstream repo keeps stale target validators and an outdated `AGENTS.md`, proving that additive upgrades warn truthfully and strict upgrades fail until the instruction layer is brought back into contract

## 1.13.2 - 2026-03-25

### Fixed

- `bootstrap/recommend-starter-blueprint.sh` now matches blueprint keywords with boundary-aware terms so generic product language like `client` no longer leaks into CLI recommendations and incidental `desktop` references do not create false desktop bias
- the starter-blueprint recommender now gives stronger weight to truthfully filled greenfield profile signals such as Flutter frameworks, mobile runtime roots, and Flutter validation commands, so a concrete Android-client repo can move from manual review to an actual `FLUTTER_ANDROID_CLIENT` recommendation before runtime code is deeply built out
- `_TEMPLATE_FACTORY/smoke-blueprint-recommendation.sh` now proves that a mobile-first greenfield repo with a filled Android/Flutter profile selects `FLUTTER_ANDROID_CLIENT` while blank installs still avoid false positives

## 1.13.1 - 2026-03-25

### Fixed

- `bootstrap/check-placeholders.sh` now ignores `## Entry format` and `## Entry template` sections so installed repos are flagged for real onboarding blanks instead of schema/example lines in working and context files
- installable bootstrap docs now describe the placeholder check in the same actionable, section-aware terms as the shipped behavior
- `_TEMPLATE_FACTORY/smoke-blueprint-application.sh` now proves that placeholder checks still catch real `PROJECT_PROFILE.md` blanks while ignoring schema-only sections in files like `FIXME.md`, `RISK_REGISTER.md`, context entry logs, and the MCP catalog

## 1.13.0 - 2026-03-23

### Changed

- `bootstrap/apply-starter-blueprint.sh` now adds a blueprint-specific risk entry to `RISK_REGISTER.md` when the repo is still carrying seeded onboarding-risk content, so explicit build-shape confirmation also sharpens the early risk picture
- explicit blueprint application now reports `RISK_REGISTER.md` in its generated handoff scope and files-changed surface so the continuity packet matches the real projected file set
- installable docs and clean-room blueprint smoke now treat risk framing as part of the explicit blueprint-projection review surface alongside product, plan, validation, design, architecture, release, and handoff state

## 1.12.0 - 2026-03-23

### Changed

- `bootstrap/apply-starter-blueprint.sh` now also projects an explicitly selected blueprint into `DESIGN_NOTES.md` and `RELEASE_NOTES.md` when those files are present, and its generated handoff text now reports that broader surface set truthfully
- installable bootstrap and working-file docs now treat design and release framing as part of the explicit blueprint-projection review surface instead of leaving those files implied or manual after build-shape confirmation
- `_TEMPLATE_FACTORY/smoke-blueprint-application.sh` now proves that explicit blueprint application reaches design and release framing in addition to the earlier product, plan, validation, queue, handoff, and architecture surfaces

## 1.11.0 - 2026-03-23

### Changed

- `bootstrap/apply-starter-blueprint.sh` now projects an explicitly selected blueprint into additional repo-local operating surfaces, including `TEST_STRATEGY.md`, `TODO.md`, `WHERE_LEFT_OFF.md`, and `ARCHITECTURE_NOTES.md` when present
- the greenfield documentation flow now tells agents to persist a recommendation first and then explicitly apply the blueprint instead of treating blueprint application as a standalone manual list-and-pick step
- `_TEMPLATE_FACTORY/smoke-blueprint-application.sh` now proves that the richer blueprint projection reaches the first validation, handoff, architecture, and queue surfaces coherently

## 1.10.0 - 2026-03-23

### Added

- `_system/AGENT_ROLE_CATALOG.md` as the canonical role and write-scope contract for multi-agent work
- `bootstrap/recommend-starter-blueprint.sh` to persist advisory blueprint recommendations with confidence and rationale
- `bootstrap/check-agent-orchestration.sh` to verify role-catalog, prompt-pack, and Cursor role-overlay alignment
- new Cursor execution-role overlays for orchestration, implementation, validation, and continuity
- `_TEMPLATE_FACTORY/smoke-blueprint-recommendation.sh` to prove fresh installs avoid false blueprint picks while real runtime or product signals still recommend coherently

### Changed

- startup, discovery, prompt-pack, and multi-agent docs now load and reference the shared role catalog instead of leaving delegation behavior implicit
- fresh install, additive install, and update now persist a starter-blueprint recommendation after product-brief seeding while keeping blueprint application explicit
- the deterministic validation chain now includes orchestration-alignment checks plus blueprint recommendation smoke
- `PRODUCT_BRIEF.md` now stores recommended blueprint, confidence, and rationale alongside the explicitly selected blueprint

### Fixed

- closed a greenfield bootstrap risk where generated runtime scaffolds could bias a naive blueprint recommender toward the wrong app shape

## 1.9.0 - 2026-03-22

### Added

- `PRODUCT_BRIEF.md` as a first-class repo-local product framing surface
- `bootstrap/seed-product-brief.sh` to turn profile signals into a bounded first-pass `PRODUCT_BRIEF.md`
- `bootstrap/apply-starter-blueprint.sh` to stamp a selected starter blueprint into the first repo-local operating surfaces
- `_TEMPLATE_FACTORY/smoke-blueprint-application.sh` to prove a clean-room repo can apply a blueprint coherently

### Changed

- Fresh install, additive install, and update now seed `PRODUCT_BRIEF.md` through the shared onboarding refresh path instead of leaving product framing manual
- Agent startup docs, host-adapter startup manifests, and working-file guidance now treat `PRODUCT_BRIEF.md` as part of the canonical greenfield shaping surface
- Install metadata now retains the repo app identity so lifecycle recovery can preserve the intended app name even when early working files are temporarily missing
- The deterministic factory proof chain now includes starter-blueprint application smoke alongside installed-repo and packaging smokes

### Fixed

- Closed a greenfield bootstrap gap where starter blueprints existed as reference docs but did not yet project themselves into repo-local execution and product-planning surfaces

## 1.8.3 - 2026-03-22

### Added

- `bootstrap/seed-risk-register.sh` to turn inferred profile and confidence signals into a bounded first-pass `RISK_REGISTER.md`

### Changed

- Fresh install, additive install, and update now seed `RISK_REGISTER.md` through the shared onboarding refresh path instead of leaving repo-local risk tracking fully manual during onboarding
- `_TEMPLATE_FACTORY/smoke-installed-repo.sh` now proves deleted `RISK_REGISTER.md` is restored and seeded during additive recovery

### Fixed

- Closed an onboarding gap where validation strategy could be seeded but the adjacent risk surface still started from a neutral blank in installed repos

## 1.8.2 - 2026-03-22

### Added

- `bootstrap/seed-test-strategy.sh` to convert inferred validation commands in `_system/PROJECT_PROFILE.md` into a first-pass `TEST_STRATEGY.md`

### Changed

- Fresh install, additive install, and update now seed `TEST_STRATEGY.md` through the shared onboarding refresh path instead of leaving validation strategy fully manual after profile inference
- `_TEMPLATE_FACTORY/smoke-installed-repo.sh` now proves deleted `TEST_STRATEGY.md` is restored and seeded during additive recovery

### Fixed

- Closed an onboarding gap where inferred validation commands existed in the project profile but the repo-local confidence model still started blank after install or recovery

## 1.8.1 - 2026-03-22

### Changed

- `bootstrap/init-project.sh`, `bootstrap/install-missing-files.sh`, and `bootstrap/update-template.sh` now share one safe onboarding refresh path after copy operations
- Additive installs and upgrades now re-run non-destructive runtime-foundation generation, profile inference, working-state seeding, and validation-state recording instead of only copying template files

### Fixed

- Closed a lifecycle recovery gap where restored or newly added AIAST files could come back without regenerated app-owned runtime scaffolds or reseeded continuity surfaces

## 1.8.0 - 2026-03-22

### Added

- Opportunistic live external-host CLI smoke via `_TEMPLATE_FACTORY/smoke-live-host-clis.sh`

### Changed

- `_TEMPLATE_FACTORY/run-automation-lane.sh` now includes optional live external-host proof in addition to optional builder smoke
- The portable baseline is now backed by real live-host transcripts on supported authenticated headless CLIs instead of only the fixture and host-bundle simulation layers

### Fixed

- Closed the live external-host transcript gap by proving the exported host-bundle flow against actual installed Codex and Cursor host CLIs on this machine

## 1.7.2 - 2026-03-22

### Added

- Factory-side golden-example promotion criteria via `_TEMPLATE_FACTORY/GOLDEN_EXAMPLES/PROMOTION_CRITERIA.md` and `_TEMPLATE_FACTORY/GOLDEN_EXAMPLES/promotion-rubric.json`
- Deterministic donor-governance validation via `_TEMPLATE_FACTORY/validate-golden-examples.sh`

### Changed

- `_TEMPLATE_FACTORY/validate-master-template.sh` now proves golden-example selection governance after scorecard refresh instead of relying on review discipline alone
- Factory donor selection now has explicit measurable thresholds plus a required review path for high-scoring non-selected repos

### Fixed

- Closed a governance gap where donor promotion quality depended too heavily on remembered reviewer intent even though scorecards and review notes already existed

## 1.7.1 - 2026-03-22

### Added

- Generated Cursor session-start and canonical context-rule overlays via `.cursor/commands/session-start.md` and `.cursor/rules/00-context-load.mdc`

### Changed

- `_system/host-adapter-manifest.json`, `bootstrap/generate-host-adapters.sh`, and `_system/HOST_ADAPTER_POLICY.md` now treat the remaining thin Cursor startup overlays as part of the managed adapter set
- The generated adapter boundary is now explicit: stable startup and context-load overlays are generated, while richer review commands, skills, and agent-specific workflows remain hand-authored until real drift justifies expansion

### Fixed

- Closed the last obvious Cursor startup drift seam by moving session-start and always-apply context-load guidance under the same canonical manifest as the other tool-entry surfaces

## 1.7.0 - 2026-03-22

### Added

- Canonical external host-bundle contract via `_system/HOST_BUNDLE_CONTRACT.md`
- Self-contained host-bundle emission via `bootstrap/emit-host-bundle.sh`
- Host-bundle validation via `bootstrap/check-host-bundle.sh`
- Separate-workspace external host-bundle smoke via `_TEMPLATE_FACTORY/smoke-host-bundle.sh`

### Changed

- The operating profile, capabilities markers, instruction-layer validation, system doctor, and factory proof chain now include host-bundle export surfaces
- External host support now has a vendor-neutral zero-repo-access path instead of relying only on live repo-path access or the earlier bounded fixture

### Fixed

- Closed a real external-ingestion gap where the system could prove a host fixture consuming repo paths but could not yet export a deterministic self-contained prompt-and-context snapshot for hosts without repo access

## 1.6.0 - 2026-03-22

### Added

- Canonical host-adapter governance via `_system/HOST_ADAPTER_POLICY.md` and `_system/host-adapter-manifest.json`
- Generated tool-adapter and load-context surfaces via `bootstrap/generate-host-adapters.sh`
- Adapter-alignment validation via `bootstrap/check-host-adapter-alignment.sh`

### Changed

- `CODEX.md`, `CLAUDE.md`, `GEMINI.md`, `WINDSURF.md`, `.cursorrules`, `.windsurfrules`, `.github/copilot-instructions.md`, `.cursor/commands/load-context.md`, and `.cursor/skills/load-context/SKILL.md` now come from the canonical host-adapter manifest instead of drifting independently
- Managed write flows now refresh generated host adapters before registry, operating-profile, and integrity regeneration
- The instruction-layer and doctor flows now validate adapter alignment as part of normal proof instead of treating tool-entry files as static prose

### Fixed

- Closed a real adapter drift gap where Cursor load-context surfaces had fallen behind the canonical precedence and operating-profile startup order

## 1.5.1 - 2026-03-22

### Added

- Factory automation entrypoint via `_TEMPLATE_FACTORY/run-automation-lane.sh` plus scheduled CI automation in `.github/workflows/validate-master-template.yml`
- Factory host-adapter fixture smoke via `_TEMPLATE_FACTORY/smoke-host-adapter-fixture.sh`
- Optional Flatpak-first builder-aware packaging smoke via `_TEMPLATE_FACTORY/smoke-packaging-builders.sh`

### Changed

- `_TEMPLATE_FACTORY/validate-master-template.sh` now includes host-adapter fixture proof in the deterministic master validation chain
- The preferred automation path is now one shared local-and-CI lane instead of relying on remembered manual release choreography
- External integration follow-up is now split cleanly between deterministic fixture proof and opportunistic real-builder proof

## 1.5.0 - 2026-03-22

### Added

- Dedicated packaging-target validation via `bootstrap/check-packaging-targets.sh` and clean-room packaging smoke via `_TEMPLATE_FACTORY/smoke-packaging-targets.sh`
- Canonical host-prompt emission via `bootstrap/emit-host-prompt.sh` plus repo-side host-ingestion validation via `bootstrap/check-host-ingestion.sh`
- Shared generated Linux desktop launcher metadata for packaging targets, including placeholder-rendered runtime template paths

### Changed

- `validate-instruction-layer.sh`, `system-doctor.sh`, and `validate-master-template.sh` now include host-ingestion and packaging-target proof instead of relying only on runtime-foundation smoke
- Runtime foundations now render placeholders in file paths as well as file contents, so generated assets can carry app-specific filenames safely
- AppImage and Flatpak scaffolds now share a generated desktop launcher file instead of duplicating launcher metadata in incompatible ways

### Fixed

- Closed a real packaging contract gap where Flatpak referenced a desktop launcher file that the runtime scaffold did not actually generate

## 1.4.1 - 2026-03-22

### Added

- Template-aware repo-mode detection for `validate-system.sh`, `check-placeholders.sh`, and `system-doctor.sh`
- Factory smoke coverage for clean-room installed repos and live runtime foundations, plus `validate-master-template.sh` as the one-command master proof chain
- Factory review notes for high-scoring donor candidates so golden-example promotion decisions survive context resets

### Changed

- The neutral source template now validates cleanly in auto/template mode while installed repos still treat unresolved repo-owned placeholders as failures
- Runtime-foundation validation now includes shell-sourceability checks for generated env defaults and executable smoke for install, repair, launch, and purge flows
- Golden-example donor curation now records explicit review outcomes for high-scoring candidates instead of leaving their deferral implicit

### Fixed

- Generated runtime env defaults with multi-word shell values are now quoted so installed launch flows can source them safely

## 1.4.0 - 2026-03-22

### Added

- Neutral golden-example system under `_system/golden-examples/` with policy, pattern guides, and exemplar working files
- Factory-only donor scoring and selection assets under `_TEMPLATE_FACTORY/GOLDEN_EXAMPLES/`
- `refresh-golden-examples.sh` to rescan sibling repos and rebuild the donor scorecard

### Changed

- Agent adapters, load-order docs, discovery docs, and bootstrap docs now point to the golden-example pack for system-evolution and working-file-authoring tasks
- Operating-profile generation, awareness checks, and system validation now treat the golden-example pack as a first-class managed surface
- Factory maintenance now tracks donor selection explicitly instead of relying on remembered chat context

## 1.3.0 - 2026-03-22

### Added

- Repo-local instruction precedence contract and machine-readable precedence manifest
- Conflict detection, operating-profile generation, and instruction-layer validation scripts
- Host-safe prompt emission contract plus compatibility markers for upstream ingestion

### Changed

- Core adapters and load-order docs now point to the precedence contract and operating profile
- Validation and doctor flows now verify instruction-layer integrity
- Upgrade, install-missing, and heal flows now refresh the operating profile alongside the registry
- Runtime-foundation defaults are template-neutral instead of carrying branded placeholder values

## 1.2.0 - 2026-03-20

### Added

- Runtime-foundation validation via `bootstrap/check-runtime-foundations.sh`
- Starter blueprints for Flutter Android clients and universal multi-surface app platforms
- Runtime scaffold checks for install scripts, env defaults, AI config, mobile manifest, and packaging manifests

### Changed

- `system-doctor.sh` now inspects generated runtime foundations in addition to system integrity
- Bootstrap and context docs now expose the new runtime checker and expanded blueprint layer

## 1.1.0 - 2026-03-20

### Added

- Runtime foundation generator for packaging, install, mobile, logging, and AI scaffolds
- Installation, packaging, mobile, and chatbot guides plus provider-config example
- Flutter-first Android starter files and packaging/signing templates
- Linux packaging manifests for AppImage, Flatpak, and Snap in generated repos
- CI examples for packaging and Android build surfaces

### Changed

- `init-project.sh` now generates project-owned runtime foundations automatically
- Project profile defaults now stamp app ids, installer paths, mobile paths, and branch-strategy guidance
- Security and observability guidance now cover installer separation, service accounts, JSON logging fields, and `logcat`

## 1.0.0 - 2026-03-19

### Added

- First-class AIAST version metadata and installed-repo metadata
- Upgrade and uninstall lifecycle scripts
- Integrity-aware drift detection and manifest policy
- Expanded project profile schema and broader repo detection
- Security scan and hardened systemd unit generation tooling
- CI, packaging, observability, and plugin-contract scaffolds

### Changed

- Bootstrap lifecycle now records install source, timestamps, and README placement
- Drift and upgrade policy now use explicit template version markers instead of commit-message convention
- Integrity manifests exclude app-owned state and project-local config surfaces
tegrity manifests exclude app-owned state and project-local config surfaces
