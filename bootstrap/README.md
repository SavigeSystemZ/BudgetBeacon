# Bootstrap

Use this directory to install, upgrade, verify, repair, and remove AIAST in a target repo.

**Orientation:** `_system/SYSTEM_ORCHESTRATION_GUIDE.md` describes the recommended order for running validators (`validate-system.sh`, awareness checks, delivery alignment, `system-doctor.sh`) and how bootstrap scripts relate to the rest of `_system/`.

## Prerequisites

- **Shell**: `bash`
- **Python 3**: required for bootstrap checks and for Python helpers emitted into the repo by runtime foundation generation.
- **Port governance** uses stdlib-only Python (no PyYAML). After `generate-runtime-foundations.sh`, governed ports are recorded under the repo `registry` tree and maintained with the allocator and checker scripts described in `_system/ports/PORT_POLICY.md`.

## Scripts

- `scaffold-system.sh` — smart entrypoint that chooses first install, additive backfill, or template update based on the target repo state
- `init-project.sh` — copy and initialize the system into a target repo
- `install-missing-files.sh` — add newly introduced template files into an existing installed repo without overwriting existing repo state, then backfill missing runtime scaffolds and safe onboarding defaults; pass `--skip-onboarding-seeds` when you must not re-run suggest/seed passes (same as `migrate-agent-surface-upgrade.sh --write`)
- `update-template.sh` — compare an installed repo with a newer template source and apply additive updates; always refresh version and contract-manifest surfaces needed for truthful upgrade state, optionally refresh broader template-managed drift, then re-run the safe onboarding backfill path
- `clear-template-sync-notice.sh` — after post-sync health checks, reset `_system/TEMPLATE_SYNC_NOTICE.md` from `PENDING_HEALTH_CHECK` to `CLEARED` (see `_system/DOWNSTREAM_PRESERVATION_AND_SYNC_NOTICE_POLICY.md`)
- `repair-system.sh` — restore missing or drifted template-managed files while preserving app-owned state
- `uninstall-system.sh` — remove the operating layer cleanly while leaving runtime app code intact
- `configure-project-profile.sh` — stamp initial profile values
- `suggest-project-profile.sh` — inspect the target repo and infer safe baseline values for structure, languages, packaging, components, and validation commands
- `seed-product-brief.sh` — turn profile values into a bounded first-pass repo-local `PRODUCT_BRIEF.md`
- `recommend-starter-blueprint.sh` — infer an advisory starter-blueprint recommendation with confidence and rationale
- `apply-starter-blueprint.sh` — stamp a selected starter blueprint into the first repo-local operating surfaces, including design, risk, and release framing when those files exist
- `seed-risk-register.sh` — turn inferred profile and confidence signals into a bounded first-pass repo-local `RISK_REGISTER.md`
- `seed-test-strategy.sh` — turn inferred validation commands into a first-pass repo-local `TEST_STRATEGY.md`
- `seed-working-state.sh` — prefill the first plan, status, and handoff surfaces for a newly installed repo
- `validate-system.sh` — verify required files, config syntax, and portability
- `check-delivery-gate-alignment.sh` — verify delivery gates and app-fill contracts are discoverable in `_system/CONTEXT_INDEX.md`, `_system/LOAD_ORDER.md`, and `_system/MASTER_SYSTEM_PROMPT.md` (also invoked by `validate-system.sh` and `system-doctor.sh`)
- `validate-instruction-layer.sh` — verify precedence, operating-profile, and prompt-emission surfaces
- `verify-integrity.sh` — generate or verify hashes for template-managed files only
- `detect-drift.sh` — report missing files, template drift, integrity failures, version skew, and stale context
- `check-repo-permissions.sh` — detect root-owned, foreign-owned, or non-writable repo files outside `.git`
- `repair-myappz-root-ownership.sh` — audit or repair root-owned paths in a broader MyAppZ workspace while excluding `_backups` by default
- `generate-system-key.sh` — rebuild the exhaustive agent-facing key for all AIAST-managed files
- `generate-system-registry.sh` — rebuild the machine-readable registry of AIAST-managed files
- `generate-host-adapters.sh` — regenerate managed tool-entry and load-context adapter files from the host-adapter manifest
- `generate-operating-profile.sh` — rebuild the compact host-ingestion profile
- `detect-instruction-conflicts.sh` — scan adapters, prompt surfaces, and manifests for overlap or contradiction
- `check-instruction-domain-alignment.sh` — validate `_system/PROJECT_DOMAIN_MANIFEST.json` and scan instruction text for manifest guard keywords (cross-product mismatch signals)
- `check-host-adapter-alignment.sh` — verify generated tool adapters are aligned with the canonical manifest
- `check-agent-surface-integrity.sh` — verify taxonomy/convergence contracts and required placeholder adapters are present
- `sync-metasystem-contracts.sh` — one-command adapter/registry/profile/integrity regeneration plus validation checks
- `migrate-agent-surface-upgrade.sh` — downstream migration assistant for the dual-metasystem agent-surface upgrade (runs `install-missing-files.sh --skip-onboarding-seeds` so product brief, working files, and context are not re-seeded; use plain `install-missing-files.sh` / `update-template.sh` when you intentionally want onboarding seeds)
- `patch-agent-surface-contracts.sh` — idempotent patcher for legacy downstream `AGENTS.md` / `_system/AGENT_DISCOVERY_MATRIX.md` references required by newer adapter-contract validators
- `check-system-awareness.sh` — verify registry coverage and path references in core docs
- `check-hallucination.sh` — detect claim-evidence mismatches and suspicious confidence drift
- `check-install-boundary.sh` — fail if maintainer-only or foreign product layers leaked into an installed repo
- `system-doctor.sh` — run the full awareness, integrity, drift, and hallucination check suite
- `heal-system.sh` — run the doctor in auto-heal mode using safe repair and registry refresh
- `run-autonomous-guardrails.sh` — run recurring guardrail checks and persist automation artifacts under `_system/automation/`
- `install-autonomous-guardrails.sh` — install recurring guardrail scheduling via user systemd timer or cron fallback (`--dry-run` prints units/cron line without installing)
- `scan-security.sh` — run applicable dependency and container scanners and persist a machine-readable report
- `generate-systemd-unit.sh` — create hardened service and timer unit files
- `print-agent-map.sh` — print the agent discovery matrix
- `check-placeholders.sh` — find unresolved actionable blanks in repo-owned operating files while ignoring entry-format and entry-template example sections
- `check-agent-orchestration.sh` — verify role-catalog, prompt-pack, and Cursor role-overlay alignment
- `check-packaging-targets.sh` — validate packaging manifests, shared desktop launchers, and generated systemd units
- `check-host-ingestion.sh` — validate prompt-emission surfaces and the canonical host-prompt emitter
- `check-host-bundle.sh` — validate the self-contained external host-bundle contract and emitter
- `check-runtime-foundations.sh` — validate generated packaging, install, mobile, env, and AI runtime scaffolds
- `emit-host-prompt.sh` — emit a host-safe prompt skeleton that defers to repo-local truth
- `emit-host-bundle.sh` — export a self-contained host bundle for external consumers that cannot read repo-local paths directly
- `emit-auxiliary-brief.sh` — emit a markdown brief for optional parallel host CLI / IDE workers (`_system/SUB_AGENT_HOST_DELEGATION.md`)
- `generate-runtime-foundations.sh` — generate project-owned packaging, install, mobile, logging, and AI scaffolds in a cloned repo

## Recommended flow

1. `scaffold-system.sh <target-repo> --app-name <name> --strict`
2. Review `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md` and `_system/REPO_OPERATING_PROFILE.md` before generating host-level prompts
3. Use `_system/READ_BUNDLES.md` when a smaller task-scoped bundle fits better than the full load order
4. Review `_system/TEMPLATE_CHANGE_IMPACT_POLICY.md` before changing installable AIAST contracts or lifecycle behavior
5. Review `_system/SELF_HEALING_BOUNDARY.md` before treating a repair as safe automatic recovery
6. Review `_system/VERSION_SENSITIVE_RESEARCH_PROTOCOL.md` when current package, platform, installer, or API behavior matters
7. Review the generated runtime scaffolds under the project root packaging, ops, mobile, and ai directories
8. Run `bash tools/security-preflight.sh` after changing runtime or deployment surfaces
9. Review the inferred `_system/PROJECT_PROFILE.md` values and correct the fields the auto-pass could not know
10. Turn `PRODUCT_BRIEF.md` into repo-specific truth and, if the repo is greenfield, run `recommend-starter-blueprint.sh` and explicitly apply the chosen starter blueprint with `apply-starter-blueprint.sh`
11. Review the projected operating surfaces first: `PLAN.md`, `TODO.md`, `TEST_STRATEGY.md`, `RISK_REGISTER.md`, `DESIGN_NOTES.md`, `ARCHITECTURE_NOTES.md`, `RELEASE_NOTES.md`, and `WHERE_LEFT_OFF.md`
12. When shaping new working files, prompt packs, or system docs, use `_system/GOLDEN_EXAMPLES_POLICY.md` and `_system/golden-examples/` as the quality-bar reference instead of copying another app
13. Re-run `validate-system.sh <target-repo> --strict`
14. Use `generate-host-adapters.sh <target-repo> --write` and `check-host-adapter-alignment.sh <target-repo>` when tool-entry or load-context adapter files change
15. Use `check-agent-surface-integrity.sh <target-repo>` when adapter naming, placeholder coverage, or convergence contracts change
16. Use `validate-instruction-layer.sh <target-repo>` or `detect-instruction-conflicts.sh <target-repo> --strict` when adapters, prompt packs, or host-safe contracts change
17. Use `sync-metasystem-contracts.sh <target-repo> --write` as the preferred all-in-one regeneration + validation flow after contract-level changes
18. Use `migrate-agent-surface-upgrade.sh <downstream-repo> --dry-run` before broad downstream rollout, then `--write` for applied upgrades
19. Use `patch-agent-surface-contracts.sh <downstream-repo> --write` when a downstream repo has the files but fails alignment due to missing AGENTS/discovery references
16. Use `emit-host-prompt.sh <target-repo> --task ...` when an upstream host or orchestrator needs a canonical repo-safe startup prompt instead of ad hoc assembly
17. Use `emit-host-bundle.sh <target-repo> --task ... --output <file>` when an external host needs a self-contained snapshot instead of live repo-path access
18. Use `check-host-ingestion.sh <target-repo>`, `check-host-bundle.sh <target-repo>`, and `check-packaging-targets.sh <target-repo>` when prompt emission, host-bundle, or packaging/systemd surfaces change materially
19. Use `check-placeholders.sh <target-repo>` for onboarding blanks, `check-agent-orchestration.sh <target-repo>` when role/delegation surfaces change, and `detect-drift.sh <target-repo> --source <template-root>` for lifecycle drift checks
20. For every `--source` flow, point at the canonical AIAST template root in template-source mode, never at the master repo root or at an already-installed app repo
21. Use `generate-system-key.sh <target-repo> --write` when the managed file set changes and you want the exhaustive agent-facing map refreshed alongside the registry
22. Use `check-install-boundary.sh <target-repo>` after installs or repairs when you want an explicit leak check for maintainer-only layers
23. Use `check-repo-permissions.sh <target-repo>` when bootstrap or editor actions may have created foreign-owned or non-writable repo files
24. Use `repair-myappz-root-ownership.sh <workspace-root>` when sibling repos or the shared template in your MyAppZ workspace picked up root ownership and you need a scoped repair command
25. Use `system-doctor.sh <target-repo> --source <template-root>` when the operating picture feels inconsistent, runtime scaffolds may be drifted, or an agent may be building on stale assumptions
26. Use `install-autonomous-guardrails.sh <target-repo>` to enable recurring guardrail runs in active repos (`--fail-on-warn` if you want warning exits to stay non-zero)
27. Monitor `_system/automation/` artifacts (see `_system/automation/README.md`) and escalate repeated warnings/failures before release claims
28. Use `update-template.sh <target-repo> --source <template-root> --dry-run` when a newer AIAST release is available
29. Use `repair-system.sh <target-repo> --source <template-root> --dry-run` or `heal-system.sh <target-repo> --source <template-root>` when integrity, awareness, or drift checks fail

Mutating lifecycle and generation commands should be run as the intended repo owner, not as `root`. If repo ownership already drifted, fix that first and then rerun the lifecycle command normally.

For workspace-wide drift outside the current repo, prefer repairing only project trees and leave `_backups` excluded unless you intentionally want to rewrite preserved ownership in snapshot material.

`scaffold-system.sh` is the preferred human-facing entrypoint. It resolves whether the target needs a first install, an additive backfill, or a fuller update path and then delegates to the canonical script for that mode. The detailed state-preservation guarantees for those flows live in `_system/INSTALLER_AND_UPGRADE_CONTRACT.md`.

`install-missing-files.sh` and `update-template.sh` now also re-run the same safe runtime-foundation generation, profile inference, product-brief seeding, blueprint recommendation, test-strategy seeding, risk-register seeding, and working-state seeding used by fresh installs, but only in the non-destructive mode that fills blanks and recreates missing generated files.

When `update-template.sh` runs in `--strict` mode, it validates the installed repo against the canonical source-template validator chain rather than trusting any drifted validator copies already living in the target repo. In non-strict mode it still completes additive upgrades, but it will print a post-update notice if preserved instruction-layer drift remains incompatible with the current source contracts.

## Existing installed repos

Installed repos carry:

- `_system/.template-version` — installed AIAST version marker
- `_system/.template-install.json` — install source, timestamps, app identity, mode, and README placement

If the target repo already has a `README.md`, the template overview is installed as `AI_SYSTEM_README.md` instead of overwriting the app README, and that placement is tracked in install metadata.

## Repo mode semantics

- `validate-system.sh`, `check-placeholders.sh`, and `system-doctor.sh` auto-detect repo mode from `_system/.template-install.json`.
- `template` mode treats neutral source-template blanks as expected while still failing absolute placeholder-path leaks.
- `installed` mode treats unresolved repo-owned placeholders as actionable failures.
- Use `--mode auto|template|installed` only when debugging or validating a copied tree outside its normal install metadata.
