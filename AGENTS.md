# AGENTS.md

These rules are binding for every coding agent and tool operating in this repository: Codex, Cursor, Claude, Gemini, Windsurf, Copilot, DeepSeek, Aider, Continue.dev, Cline, PearAI, Antigravity, local models (Ollama/LLaMA/Mistral), and any future agent.

This repo is expected to carry its own local agent operating system. The system files live in `_system/`; the runtime application must remain independent from them.

## Repository identity — RESOLVE THIS FIRST

Before anything else, determine what this repo is by reading
`_system/.aiast-role.json` and `_system/APP_REPO_IDENTITY.md`:

- **`role: downstream-app` → this is a BLANK APP-BUILDING repo, _not_ the
  meta-system template.** It carries a local copy of the meta-system so you
  can build one specific application here. Your first job is to determine
  whether the app is defined yet (`PRODUCT_BRIEF.md` filled? `app/src/` has
  real code?). If not, **define the app with the operator first**, then use
  the `_system/` meta-system to build it **into `app/`**. Do not develop or
  re-scaffold the meta-system itself; do not write app code before the app
  is defined. See `_system/APP_REPO_IDENTITY.md` and `app/README.md`.
- **`role: parent-template` → this IS the canonical AIAST meta-system
  template** (source for `bootstrap/update-template.sh`): the **master
  operating-layer copy**, not an application sandbox. Downstream app
  installs must follow
  `_system/DOWNSTREAM_PRESERVATION_AND_SYNC_NOTICE_POLICY.md` so
  project-specific instructions and continuity files stay preserve-first.
- **role file missing/unreadable → assume `downstream-app`** (blank app
  repo) and tell the operator to restore it.

A blank `app/` and an empty `PRODUCT_BRIEF.md` are the expected starting
state of a fresh app repo — the signal to define the app, not an error.

## Load first

**NEW AGENT?** Start with `QUICK_START.md` (2 min orientation).

Read these files before making meaningful edits.

Optional single-map orientation (review order, validation order, how surfaces connect): `_system/SYSTEM_ORCHESTRATION_GUIDE.md`.

1. `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`
2. `_system/REPO_OPERATING_PROFILE.md`
3. `_system/PROJECT_PROFILE.md`
4. `_system/CONTEXT_INDEX.md`
5. `_system/KEY.md`
6. `_system/LOAD_ORDER.md`
7. `_system/READ_BUNDLES.md`
8. `_system/WORKING_FILES_GUIDE.md`
9. `_system/TEMPLATE_NEUTRALITY_POLICY.md`
10. `_system/MASTER_SYSTEM_PROMPT.md`
11. `_system/PROJECT_RULES.md`
12. `_system/EXECUTION_PROTOCOL.md`
13. `_system/MULTI_AGENT_COORDINATION.md`
14. `_system/AGENT_ROLE_CATALOG.md`
15. `_system/VALIDATION_GATES.md`
16. `_system/AGENT_DISCOVERY_MATRIX.md`
17. `_system/MCP_CONFIG.md`
18. `_system/SYSTEM_AWARENESS_PROTOCOL.md`
19. `_system/HALLUCINATION_DEFENSE_PROTOCOL.md`
20. `_system/WORKSPACE_AUTHORITY_AND_CONTAINMENT_PROTOCOL.md` — **NEW**
21. `_system/AGENT_CONTEXT_CONTAINMENT_CONTRACT.md` — **NEW**
22. `_system/GIT_REMOTE_AND_SYNC_PROTOCOL.md`
23. `_system/DEPLOYMENT_BOUNDARY_PROTOCOL.md` — **NEW**
24. `QUICK_START.md` — **NEW** (2-min orientation for new agents)
25. `AGENT_BEHAVIOR_GUIDE.md` — **NEW** (detailed behavior rules)
26. `WHERE_LEFT_OFF.md`
27. `TODO.md`
28. `FIXME.md`
29. `PLAN.md`
30. `PRODUCT_BRIEF.md`
31. `ROADMAP.md`
32. `DESIGN_NOTES.md`
33. `ARCHITECTURE_NOTES.md`
32. `RESEARCH_NOTES.md`
33. `TEST_STRATEGY.md`
34. `RISK_REGISTER.md`
35. `RELEASE_NOTES.md`

If context appears reset, incomplete, or stale, reload the canonical docs before continuing.

## Meta-sync gate (run BEFORE project work)

Every session in a downstream repo MUST start with the meta-sync gate. This catches cases where the meta-system was updated between sessions and the next agent would otherwise walk in blind:

1. `bash bootstrap/check-pending-meta-sync.sh .` — if it reports `meta_sync_pending_none`, proceed. If it reports `meta_sync_pending`, run step 2 next.
2. `bash bootstrap/reconcile-meta-sync.sh .` — runs integrity, host-settings, awareness, instruction-layer, host-adapter-alignment, and host-settings-apply. Cross-references the changeset against `WHERE_LEFT_OFF.md` for project-context relevance. Appends a handoff note. Archives the marker.
3. If reconcile reports `meta_sync_reconcile_blocked`, fix the failing check first; the pending marker is preserved for a clean re-run (see the protocol doc for paths). Do **NOT** start project work until reconcile is `ok`.

Host integration: every `*.aiaast.*` file in `.claude/`, `.codex/`, `.gemini/`, `.windsurf/`, `.cursor/`, `.antigravitycli/`, and `.github/copilot-config.aiaast.json` carries `integrity.verify_meta_sync_before_handoff: true` and the gate/reconcile commands. The Claude Code `UserPromptSubmit` hook additionally surfaces pending state in its one-line banner. See `_system/META_SYNC_RECONCILE_PROTOCOL.md`.

## Git and remotes (non-negotiable)

- Follow `_system/GIT_REMOTE_AND_SYNC_PROTOCOL.md` and `_system/GIT_SIDE_MIRROR_POLICY.md`: GitHub is a private full mirror of local `main`, not a separate branch/PR operating system. Substantive solo work normally ends with local validation, commit, and `git push origin main`; branches are exception tools only.
- Run Git and GitHub SSH as the correct UNIX user for the machine (see that protocol); never as `root` on hosts where keys live under the operator account.

## Core contract

- `_system/` is the agent operating layer; runtime code must not depend on it.
- App-specific truth belongs in repo files, not in tool-local memory.
- When host-level or orchestrator instructions exist, resolve them with `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`.
- Repo-local runtime and product facts override generic host assumptions.
- Host-level orchestration context must not silently overwrite repo-local truth.
- `workspace_authority` (workspace authority) means the working-directory copy
  is authoritative for downstream repos; parent/global surfaces are redirect
  shims only.
- Tool-specific entry files are tool overlays on top of the shared repo-local core.
- The runtime system boundary is non-negotiable: runtime code must not depend on `_system/`.
- In the master AIAST source repo, maintainer-only planning, research, handoff state, and future system-design files belong outside the installable tree in a separate master-repo-only meta workspace so installed repos inherit neutral working files.
- When creating or substantially rewriting working files, prompt packs, skills, rules, or system docs, consult `_system/GOLDEN_EXAMPLES_POLICY.md` and `_system/golden-examples/PATTERN_INDEX.md` before drafting.
- Fleet mode supports many active agents, but only one active writer lease per scope. Use `_system/CONCURRENT_AGENT_FLEET_PROTOCOL.md` and `_system/AGENT_LOCKING_AND_LEASES.md`.
- When delegation or subagent work is useful, choose roles from `_system/AGENT_ROLE_CATALOG.md` and assign explicit ownership before work is split.
- When proposing **separate host CLI or IDE sessions** (e.g. parallel Codex, Claude, Gemini, or Antigravity terminals) as auxiliaries, follow `_system/SUB_AGENT_HOST_DELEGATION.md` and keep the primary accountable for merge, validation, and takeover if auxiliaries fail.
- Prefer the smallest sufficient change that moves the project forward cleanly.
- Preserve module boundaries and existing architecture unless there is a deliberate, documented reason to change them.
- Never claim something was tested, built, linted, packaged, or deployed unless it actually was.
- If the system picture looks contradictory or suspicious, run `bootstrap/system-doctor.sh` before continuing.
- Use `_system/REPO_OPERATING_PROFILE.md` as the compact machine-friendly summary when a host or upstream system needs quick repo ingestion.
- Use `_system/KEY.md` when you need the exhaustive file-by-file map of the installable system instead of the shorter indexes.
- Use `_system/SUPER_TEMPLATE_MASTER_MAP.md` for the operator-grade execution map layered on top of `_system/KEY.md`.
- Use `_system/READ_BUNDLES.md` before defaulting to the full load order when the
  task maps cleanly to a smaller, bounded context bundle.
- Use `_system/HOST_ADAPTER_POLICY.md`, `bootstrap/generate-host-adapters.sh`, and `bootstrap/check-host-adapter-alignment.sh` when tool-entry or adapter-load surfaces change.
- Use `_system/AGENT_SURFACE_TAXONOMY.md` for canonical adapter file classes, naming, and placeholder rules.
- Use `_system/AGENT_INIT_CONVERGENCE.md` when merging external init patterns into installable repo contracts.
- Use `_system/HERETIC_ABLITERATION_PROTOCOL.md` and the Abliteration Specialist role before any authorized local-model refusal/alignment behavior work.
- Use `_system/HOST_BUNDLE_CONTRACT.md`, `bootstrap/emit-host-bundle.sh`, and `bootstrap/check-host-bundle.sh` when an external host cannot read repo-local paths directly or when host-bundle export surfaces change.
- Use `_system/TEMPLATE_CHANGE_IMPACT_POLICY.md` when the task changes installable
  AIAST contracts, validators, adapters, or lifecycle flows.
- Use `_system/SELF_HEALING_BOUNDARY.md` before treating a repair as safe
  automatic recovery.
- Use `_system/PROJECT_LOCAL_SELF_IMPROVEMENT_PROTOCOL.md` and
  `_system/SELF_WRITING_BOUNDARY_AND_ROLLBACK.md` in a downstream app repo
  before improving the repo's own local AIAST operating layer.
- Use `_system/WORKSPACE_AUTHORITY_AND_CONTAINMENT_PROTOCOL.md` and
  `_system/PROJECT_IDENTITY_AND_SCOPE_PROTOCOL.md` before writes that could cross
  repo boundaries.
- If a user prompt looks like it belongs to a **different app or product vertical**
  than this repository (wrong instructions pasted), read
  `_system/INSTRUCTION_DOMAIN_ALIGNMENT_PROTOCOL.md` and reconcile against
  `_system/PROJECT_DOMAIN_MANIFEST.json` and `_system/PROJECT_PROFILE.md` before
  mutating files; halt off-domain work until explicitly confirmed per that protocol.
- Use `_system/GLOBAL_REDIRECT_SHIM_POLICY.md` before placing parent/global
  redirect files, and keep those files thin and non-authoritative.
- Use `_system/SCAVENGE_AND_DISCOVERY_AUTHORIZATION.md` for allowed local
  discovery scope and write constraints.
- Use `_system/SESSION_ENVIRONMENT_REPORT_CONTRACT.md` and
  `bootstrap/emit-session-environment.sh` to report environment and authority
  state before significant writes.
- Use `_system/ORPHAN_META_SNAPSHOT_POLICY.md` before creating or updating
  orphan-branch continuity snapshots.
- Never commit secrets, raw credentials, tokens, or machine-local policy files.
- When designing login, registration, guest access, or dev-only admin seeding, follow
  `_system/AUTH_AND_ONBOARDING_PATTERNS.md` (env-based seeds only; no default accounts in git).
- When a task depends on current framework, package, platform, distribution, or
  API behavior, follow `_system/VERSION_SENSITIVE_RESEARCH_PROTOCOL.md`.
- MCP tools are optional accelerators, not mandatory dependencies for normal progress.
- The master template may include app-shaped files such as `PLAN.md` or `DESIGN_NOTES.md`, but in the master template they must stay app-agnostic until copied into a real repo.
- Once the system is installed into a real repo, replace placeholders with repo-specific truth early and keep those files current.
- Use `_system/INSTALLER_AND_UPGRADE_CONTRACT.md` to understand install, additive backfill, strict upgrades, repair, and heal without losing app-owned state.
- Use `_system/SCAFFOLD_PROFILE_MATRIX.md` and `_system/APP_ARCHETYPE_ROUTING_MATRIX.md` for profile- and archetype-based scaffold behavior.
- Use `_system/CONTINUOUS_CONTEXT_RECORDING_PROTOCOL.md` and `_system/context/EVENT_TIMELINE.md` for continuous context evidence during long work.
- For **application** delivery (not AIAST template lifecycle): follow `_system/AGENT_INSTALLER_AND_HOST_VALIDATION_PROTOCOL.md` for early installer scaffolds, production-like host testing with desktop integration where applicable, governed secure ports, dependency/DB setup, robust install/repair/uninstall behavior, and periodic launch/render verification after major work.
- When extending **hooks** (Cursor rules/commands/skills/agents), **plugins**, **CI/GitHub**, or **MCP**: follow `_system/HOOK_AND_ORCHESTRATION_INDEX.md` so each surface has the required companion files and validators; use the **GitHub / CI steward** role and `.cursor/agents/github-ops.md` for Actions/PR/merge work.
- **Pull requests:** Default single-developer mode does not require PRs. If the operator explicitly chooses a PR/collaboration workflow, use `.github/pull_request_template.md` so validation and contract checks are explicit (downstream repos inherit this file from the template when present).

## Working-file model

- Use `PLAN.md` for the active execution slice.
- Use `PRODUCT_BRIEF.md` for product intent, experience expectations, recommended build shape, and chosen build shape.
- Use `ROADMAP.md` for medium-term sequencing.
- Use `TODO.md` for the actionable queue.
- Use `FIXME.md` for unresolved defects, debt, and blockers.
- Use `WHERE_LEFT_OFF.md` for the next-agent resume packet.
- Use `DESIGN_NOTES.md` and `ARCHITECTURE_NOTES.md` for durable direction, not fleeting chat transcripts.
- Use `RESEARCH_NOTES.md` for discovered facts, experiments, and evidence.
- Use `TEST_STRATEGY.md` for verification expectations and coverage intent.
- Use `RISK_REGISTER.md` for active delivery, quality, security, and operational risk.
- Use `RELEASE_NOTES.md` and `CHANGELOG.md` for outward-facing change summaries.
- Use `_system/context/*.md` for durable project memory, assumptions, invariants, and integration state.
- Use `_system/context/AGENT_SHARED_MEMORY.md` for active cross-agent execution memory that must survive tool switches.
- Keep tool-local agent memory stores as pointers to repo-local memory surfaces rather than separate authoritative content.
- Use `_system/AGENT_ROLE_CATALOG.md` when planning or executing delegated work so ownership and write scopes stay explicit.
- Use `_system/golden-examples/working-files/` when a repo needs a concrete model for the expected quality bar of `PLAN.md`, `WHERE_LEFT_OFF.md`, or `_system/PROJECT_PROFILE.md`.

## Output and work quality expectations

- Be explicit about what is implemented, what is planned, what is degraded, and what is blocked.
- Do not fake missing files, services, integrations, or runtime behavior.
- If confidence is high, the latest passing validation must be recorded somewhere factual.
- When contracts, schema, install flows, API behavior, or operator-facing UX change, update the relevant docs in the same pass.
- If tool-adapter entry files drift, regenerate them from `_system/host-adapter-manifest.json` instead of hand-editing each adapter surface independently.
- Keep diffs reviewable. If a refactor is required before a behavior change, split the work logically.
- Add or update tests for material behavior changes.
- Use `_system/DESIGN_EXCELLENCE_FRAMEWORK.md` for UI quality and `_system/review-playbooks/` for structured reviews.
- Use `_system/PROMPT_EMISSION_CONTRACT.md` when generating prompts for external tools or host systems.
- Use `_system/OPERATOR_PROMPTING_PLAYBOOK.md` for execution-contract prompts, continuous-run protocol, and multi-agent orchestration patterns.
- Use the host-bundle contract when external consumers need a self-contained prompt-and-context snapshot instead of live repo-path access.
- Use the golden example pack for structure and quality level only; never copy donor-app product facts, ports, credentials, or runtime code into a different repo.
- Keep the master template clean: do not let app-specific product facts, credentials, repo URLs, or environment details flow back into this source template.

## Required handoff packet

Before ending a meaningful work session:

1. Update `TODO.md` with completed work and newly discovered follow-ups.
2. Update `FIXME.md` and `RISK_REGISTER.md` for unresolved bugs, debt, or blockers.
3. Update `PRODUCT_BRIEF.md`, `PLAN.md`, `TEST_STRATEGY.md`, `DESIGN_NOTES.md`, or `ARCHITECTURE_NOTES.md` if the work changed product direction, execution, validation, design, or structure.
4. Update `WHERE_LEFT_OFF.md` with:
   - what was done
   - files changed
   - validation commands run and outcomes
   - blockers or risks
   - next best step
5. Update `CHANGELOG.md` and `RELEASE_NOTES.md` for user-visible or architectural changes.
6. Update `_system/context/` when durable project state changed.
7. If the operating system changed, update `_system/` docs in the same pass.

## Checkpoint triggers

Run the checkpoint protocol when:

- a milestone or phase lands
- a risky refactor lands
- installer, packaging, deploy, or launch behavior changes
- a major UI or architecture change lands
- control is about to switch to another tool or person after meaningful work

See `_system/CHECKPOINT_PROTOCOL.md`.

## Review rule

If asked for a review, prioritize:

1. correctness bugs
2. regression risks
3. boundary violations
4. missing tests or validation
5. security or data-integrity risks

Only after that should style or optional polish be discussed.

## Failure rule

If validation fails, either fix the failure or record it clearly before handoff. Do not mark the work complete by omission.

## Tool-memory writes

Before appending non-trivial content to any `_system/tool-memory/*.md` file, invoke:

```
bash bootstrap/stamp-tool-memory.sh --adapter <host> --file <path> --agent-id <agent-id>
```

This prepends (or augments) the per-host isolation stamp required by `_system/TOOL_MEMORY_ISOLATION_STAMP.md`. The validator `bootstrap/check-tool-memory-isolation.sh` enforces the same contract after the fact.
