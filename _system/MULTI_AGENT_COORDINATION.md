# Multi-Agent Coordination

This repo is designed to survive tool changes, interrupted sessions, and handoff between multiple agents and humans.

## Supported tools

- Codex
- Cursor
- Claude
- Gemini
- Windsurf
- Copilot
- DeepSeek
- Aider
- Continue.dev
- Cline
- PearAI
- Local models (Ollama / LLaMA / Mistral)
- Other compatible agents

## Required operating model

1. Single active writer at a time.
2. Shared governance lives in repo files, not tool-local memory.
3. Use `_system/AGENT_ROLE_CATALOG.md` to choose roles and write-scope ownership before splitting work.
4. Validators and reviewers are read-only by default unless they are explicitly reassigned into repair work.
5. The context curator owns continuity updates by default when a dedicated continuity pass is needed.
6. Handoff files are mandatory:
   - `TODO.md`
   - `FIXME.md`
   - `WHERE_LEFT_OFF.md`
7. Supporting working files should be updated when the task touches their domain:
   - `PRODUCT_BRIEF.md`
   - `PLAN.md`
   - `DESIGN_NOTES.md`
   - `ARCHITECTURE_NOTES.md`
   - `RESEARCH_NOTES.md`
   - `TEST_STRATEGY.md`
   - `RISK_REGISTER.md`
   - `RELEASE_NOTES.md`
8. Tool-specific helpers may extend behavior but must not contradict `AGENTS.md` or `_system/`.
9. Adapter placeholders (`CURSOR.md`, `COPILOT.md`, `AIDER.md`, `AGENT_ZERO.md`) are compatibility pointers only; shared governance stays in `AGENTS.md` and `_system/`.
10. Hook and orchestration surfaces (Cursor rules/commands/skills/agents, plugins, CI, MCP) must stay coherent; see `_system/HOOK_AND_ORCHESTRATION_INDEX.md`.

## Role activation

- Orchestrator / planner: chooses the slice, assigns ownership, and decides whether delegation is worth the coordination cost.
- Implementation worker: the active writer for runtime or system changes.
- Validator: proves behavior and challenge-checks claims without taking ownership of the same files by default.
- Context curator: updates handoff, working-state, and continuity surfaces.
- Specialist reviewers: architecture, design, security, and release roles provide bounded read-only review.
- GitHub / CI steward: merge readiness, workflow edits, PR checks—see `_system/AGENT_ROLE_CATALOG.md` and `.cursor/agents/github-ops.md`.

## Start-of-turn checklist

- Load the canonical docs.
- Load `_system/AGENT_ROLE_CATALOG.md` if delegation, review, or multi-agent work is likely.
- Read `WHERE_LEFT_OFF.md`.
- Read `TODO.md` and `FIXME.md`.
- Read additional working files that match the task domain.
- Review current repo state before editing.
- Confirm whether another tool's unfinished work is present.

## End-of-turn checklist

- Update handoff files.
- Record validation results.
- Note blockers and risk honestly.
- Leave the next best step explicit.
- Run checkpoint flow if the work crossed a milestone or risky boundary.

## Takeover protocol

When taking over work started by another tool:

1. Read the handoff packet and current working files.
2. Verify the repo state matches the claimed state before building on it.
3. If the previous work looks incomplete or risky, stabilize and document before broadening scope.
4. If you must redirect the approach, explain why in the relevant working files.

## Delegation rules

1. Name the role before assigning the task.
2. Name the owner and write scope before parallel work begins.
3. Parallel writers are allowed only when their write scopes do not overlap.
4. Validators and reviewers should verify or critique, not silently co-own implementation files.
5. If write ownership becomes unclear, pause, shrink scope, and restabilize the handoff.

## Swarm Fleet Branching & Commit Delegation

When operating in **Swarm Fleet Mode**, the following rules are non-negotiable:

1. **Branch Isolation:** Each agent MUST work on a dedicated task-isolated branch following the pattern `ai/<agent_name>/<feature>`.
2. **Branch Discovery:** The active swarm branch must be explicitly documented in `WHERE_LEFT_OFF.md`.
3. **Commit Tooling:** Agents are FORBIDDEN from using raw `git commit` on swarm branches. They MUST use `TEMPLATE/bootstrap/git-swarm-manager.sh auto-push` to ensure semantic consistency and remote synchronization.
4. **Integration Lane:** The `dev` branch is the primary integration lane. Agents must not push directly to `main`.
5. **Squash Merges:** Only the `fleet_architect` or the human operator (`whyte`) is authorized to execute `git-swarm-manager.sh squash-merge` to fold an AI branch back into `dev`.

## Resilience & Self-Healing

1. **MCP Heartbeat:** Agents MUST verify MCP connectivity at the start of their turn.
2. **Failure Fallback:** If an MCP server fails, follow the `_system/mcp/MCP_SURVIVAL_PLAYBOOK.md` immediately. Do not stall.
3. **Task Reclamation:** If an auxiliary agent stops providing "Heartbeats" (status updates in PLAN.md or WHERE_LEFT_OFF.md) for more than 2 turns, the primary orchestrator MUST reclaim the task and document the failure.
4. **Repair Protocol:** If agent logic or IDE state becomes corrupted, run `bootstrap/repair-swarm-integrity.sh --full`.

## Optional host CLI auxiliaries (“sub-agents”)

Some workflows use **separate terminal or IDE sessions** (e.g. Codex, Claude, Gemini CLIs) as
auxiliary workers alongside the primary tool. That is **environment-dependent** and **not**
auto-provided by AIAST. When you use or propose such parallelism, follow
`SUB_AGENT_HOST_DELEGATION.md`: cap concurrent auxiliaries (prefer at most two), keep write scopes
disjoint, obtain operator consent, and ensure the **primary can take over** if an auxiliary
fails.

## Handoff packet format

Each meaningful handoff should include:

- objective worked on
- completion status
- exact files changed
- commands run and pass/fail result
- blockers and risks
- next best step

## Conflict policy

- Do not overwrite unresolved work from another agent without documenting why.
- Prefer additive follow-up patches over silent rewrites.
- If overlapping work is unavoidable, reduce the scope and stabilize the handoff first.
- If a previous agent updated design or architecture direction, load those files before changing course.
- If a conflict appears between generated adapters and placeholder adapters, generated adapter policy and shared `_system/` contracts take precedence.

## Tool fit

- Cursor / Windsurf: good implementation-worker or review overlays when file-aware navigation matters.
- Codex: good implementation-worker, validator, or repair role when precise patching matters.
- Claude / Gemini: good orchestrator, architecture reviewer, or design/system reviewer roles.
- Copilot: good inline implementation support under the same repo rules.
- DeepSeek: strong code generation and debugging; good implementation-worker for code-heavy tasks.
- Aider: good for precise multi-file edits and CLI-driven pair programming workflows.
- Continue.dev / PearAI: good IDE-integrated implementation support with autocomplete and chat.
- Cline: good for autonomous multi-step implementation with terminal awareness.
- Local models: good for offline or privacy-sensitive work; use tiered context loading for smaller models.

Tool fit is secondary to the canonical role model and explicit ownership.
