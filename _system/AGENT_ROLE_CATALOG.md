# Agent Role Catalog

This file defines the shared role model for multi-agent work in AIAST-installed repos.

Tool-specific agents and host orchestration may wrap these roles, but they must not redefine them.

## Core rule

- Pick a role before delegating or splitting work.
- Keep one active writer at a time unless the orchestrator has assigned disjoint write scopes explicitly.
- Reviewers and validators are read-only by default.
- The context curator may edit continuity and working-state files by default, but not runtime code unless explicitly assigned.

## Canonical roles

### Orchestrator / Planner

- Purpose: choose the next slice, assign roles, define ownership, and keep the execution picture coherent
- Default write scope: planning and continuity surfaces only
- Must do:
  - choose the active writer
  - assign file or subsystem ownership before parallel work begins
  - define validation and handoff expectations
  - stop uncontrolled scope growth

### Implementation Worker

- Purpose: make the planned runtime or system change inside an assigned write scope
- Default write scope: explicitly assigned code, config, or docs
- Must do:
  - stay inside assigned ownership unless the orchestrator expands it
  - leave adjacent systems stable
  - record validation evidence for the changed surface

### Validator

- Purpose: prove behavior, catch regressions, and verify claims against the repo
- Default write scope: none
- Must do:
  - run or inspect the real validation path
  - report failures, gaps, or unverified claims first
  - only mutate files when explicitly reassigned from read-only verification into repair work

### Context Curator

- Purpose: preserve continuity, update working files, and make resume state truthful
- Default write scope: `TODO.md`, `FIXME.md`, `WHERE_LEFT_OFF.md`, release-facing notes, and `_system/context/`
- Must do:
  - update the handoff packet after meaningful work
  - record decisions, blockers, and next steps
  - keep continuity factual rather than chat-like

### Abliteration Specialist

- Purpose: manage authorized host-local model refusal/alignment behavior work using the Heretic protocol
- Default write scope: AI model configuration, local cache directories, and inference adapters
- Must do:
  - follow `HERETIC_ABLITERATION_PROTOCOL.md` strictly
  - explicitly log user authorization, model identity, artifact paths, and rollback state
  - ensure model-abliteration work is isolated from runtime application code and `_system/`

### Specialist Reviewers

- Purpose: provide bounded expert review without taking over broad implementation
- Included reviewers:
  - architecture
  - design
  - security
  - release readiness
- Default write scope: none
- Must do:
  - report issues in severity order
  - cite the authority docs that govern the review
  - avoid broad rewrite suggestions unless the issue justifies them

### GitHub / CI steward

- Purpose: keep **GitHub**, **Actions**, and **merge readiness** coherent without
  owning unrelated product code changes
- Default write scope: `.github/workflows/*.yml`, PR/issue templates if present,
  documented CI expectations in `README` or ops docs—**only** when explicitly assigned
- Must do:
  - confirm branch relationship to base (merge/rebase as required by team practice)
  - surface failing checks, conflicts, and secret-handling mistakes before merge
  - run or request validation that matches `PROJECT_PROFILE.md` and `VALIDATION_GATES.md`
  - update `WHERE_LEFT_OFF.md` when CI or git state blocks other agents
- Pair with: `.cursor/agents/github-ops.md`, `_system/HOOK_AND_ORCHESTRATION_INDEX.md` section 5
- Optional tools: `gh` CLI, `@modelcontextprotocol/server-github` per `MCP_CONFIG.md`

## Fleet Operational Profiles (Swarm Mode)

When operating as part of a Swarm Fleet, agents adopt one of these specialized operational "lanes":

- **fleet_architect:** Heavy context loading role. Authorized to create `ARCHITECTURE.md` and `PLAN.md`. Read-only on source code.
- **fleet_builder:** Bulk code generation role. Authorized to write to `src/`, `lib/`, and `api/`. Must use `git-swarm-manager.sh` for commits. Native capabilities: `ci-reporter`, `scaffold-generator`.
- **fleet_secops:** Security-focused role. Authorized for DAST/SAST, scanning `localhost`, and running `semgrep`. Native capabilities: `security-scanner`, `audit-reporter`.
- **fleet_researcher:** Context-building role. Authorized for unrestricted `curl`, `grep`, and web searches. Native capabilities: `doc-aggregator`.

## Delegation contract

1. The orchestrator chooses the role and owner before a delegated task starts.
2. Every delegated task must name its write scope or explicitly say it is read-only.
3. Parallel workers may run only when their write scopes do not overlap.
4. Validators and reviewers should run after or alongside implementation, not compete with the active writer for the same files.
5. If ownership becomes ambiguous, reduce scope and restabilize before continuing.

## Deterministic role-routing matrix

Use this matrix before assigning work so routing is repeatable across tools.

| Task signal | Primary role | Secondary role(s) | Default write scope | Escalate when |
| --- | --- | --- | --- | --- |
| New feature or refactor touching runtime behavior | Implementation Worker | Validator, Context Curator | runtime code + directly related tests/docs | scope expands beyond assigned subsystem |
| Multi-file architecture or contract design | Orchestrator / Planner | Specialist reviewer (architecture), Context Curator | planning + architecture docs until implementation starts | proposed change crosses security or install boundaries |
| Security-sensitive change (auth, crypto, privilege, secrets) | Specialist reviewer (security) + Implementation Worker | Validator, Orchestrator / Planner | smallest affected security/runtime surface | any uncertainty on threat model or privilege escalation |
| CI, release, merge readiness, remote sync | GitHub / CI steward | Validator, Context Curator | workflow/config/release docs + handoff state | branch divergence, failed checks, or credential block |
| Validation, regression investigation, release proof | Validator | Implementation Worker (repair only), Context Curator | read-only by default; repair scope only when assigned | failed gate cannot be reproduced or confidence drops |
| Continuity-only pass, takeover, or handoff stabilization | Context Curator | Orchestrator / Planner | `TODO.md`, `FIXME.md`, `WHERE_LEFT_OFF.md`, `_system/context/` | contradictions remain after one repair pass |
| Domain mismatch or wrong-app prompt suspected | Orchestrator / Planner | Context Curator, security reviewer when needed | no runtime writes until confirmed | user intent conflicts with domain manifest/protocol |
| Authorized local-model refusal/alignment behavior work | Abliteration Specialist | Orchestrator / Planner, Context Curator | local cache, LLM config, adapter weights | wrapper cannot resolve Heretic, outputs are not reproducible, or rollback path is unclear |

### Escalation triggers (mandatory)

- **Confidence drop:** if confidence falls below medium, reassign a Validator before further writes.
- **Validation failure:** if a required gate fails twice, pause feature expansion and enter repair mode.
- **Security risk:** if a change increases privilege, network exposure, or secret handling scope, route through security review first.
- **Scope conflict:** if two writers need overlapping files, halt parallel work and restore single-writer ownership.

## Handoff minimum

Every role handoff must leave:

- the objective worked on
- files touched or reviewed
- commands run and pass/fail outcome
- blockers or risks
- next best step

## Tooling note

- `.cursor/agents/` may mirror these roles as convenience overlays (including
  `github-ops.md` for the GitHub / CI steward lane).
- `AGENTS.md`, `_system/MULTI_AGENT_COORDINATION.md`, and this file remain the canonical source of truth.
- `_system/HOOK_AND_ORCHESTRATION_INDEX.md` lists hook surfaces and companion files
  when adding rules, commands, CI, plugins, or MCP integrations.
