# Hook And Orchestration Index

Single map of **build-out hooks**, **tool-specific surfaces**, **validation triggers**,
and **companion files** agents must keep coherent when extending the operating
system. Use this when adding commands, rules, plugins, MCP usage, CI, or GitHub
automation.

**Orientation:** For how this index fits the rest of the operating system (startup order, validation order, related contracts), read `_system/SYSTEM_ORCHESTRATION_GUIDE.md` before large hook or CI changes.

## Principles

1. **Repo-local truth wins** — Host prompts and MCP output are context; `AGENTS.md`
   and `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md` resolve conflicts.
2. **One writer** unless `MULTI_AGENT_COORDINATION.md` and delegation rules say otherwise.
3. **Hooks are contracts** — Changing a hook surface requires updating validators,
   docs, and handoff notes in the same slice when feasible.
4. **Current-state tooling facts expire** — When hook, CI, MCP, packaging, or
   host behavior depends on versions or current vendor behavior, follow
   `_system/VERSION_SENSITIVE_RESEARCH_PROTOCOL.md`.

## 1. Session and IDE workflow hooks (Cursor-class)

| Hook / surface | Purpose | Companion files to keep aligned |
|----------------|---------|-----------------------------------|
| **Rules** `.cursor/rules/*.mdc` | Auto-loaded behavior (boundaries, validation, MCP, Composer) | After edits: `bootstrap/validate-instruction-layer.sh`, `bootstrap/detect-instruction-conflicts.sh` |
| **Commands** `.cursor/commands/*.md` | Repeatable workflows (verify, session-start, composer-session, compress-context) | `.cursor/README.md`, `PROMPTS_INDEX.md` if command duplicates a prompt pack |
| **Skills** `.cursor/skills/*/SKILL.md` | Portable task recipes | `SKILLS_INDEX.md` (includes opt-in `concise-communication` for token-efficient **output**; `compress-context-input` for opt-in **input** prose compression under `docs/`/`notes/`) |
| **Environment report** `.cursor/commands/environment.md` + `bootstrap/emit-session-environment.sh` | Session authority/mode/identity reporting before write-heavy work | `_system/SESSION_ENVIRONMENT_REPORT_CONTRACT.md`, `_system/WORKSPACE_AUTHORITY_AND_CONTAINMENT_PROTOCOL.md`, `_system/PROJECT_IDENTITY_AND_SCOPE_PROTOCOL.md` |
| **Delegated agents** `.cursor/agents/*.md` | Role overlays for Composer / multi-agent UIs | `_system/AGENT_ROLE_CATALOG.md`, `.cursor/agents/README.md` |
| **MCP config** `.cursor/mcp.json` | Tool servers for this workspace | `_system/MCP_CONFIG.md`, secrets never in git |

**Build-out order for new Cursor hooks:** add rule/command/skill → reference from
`CONTEXT_INDEX.md` or `PROMPTS_INDEX.md` if user-discoverable → run
`bootstrap/check-host-adapter-alignment.sh` after adapter-adjacent edits.

## 2. Tool-specific adapter files (multi-host)

Each host has a **primary adapter**; all must stay consistent with `AGENTS.md`.

| Tool | Primary file | Notes |
|------|--------------|--------|
| Cursor | `.cursorrules` + `.cursor/` | Generated; edit `TEMPLATE/_system` sources via host generator |
| GitHub Copilot | `.github/copilot-instructions.md` | Also load this index when touching CI/GitHub |
| Claude | `CLAUDE.md` | Root adapter |
| Codex | `CODEX.md` | |
| Gemini | `GEMINI.md` | |
| Windsurf | `WINDSURF.md`, `.windsurfrules` | |
| Continue / Cline / Aider / others | `.continuerules`, `.clinerules`, `.aider.conf.yml`, … | See `AGENT_DISCOVERY_MATRIX.md` |

Regenerate adapters after contract changes: `bootstrap/generate-host-adapters.sh`.

## 3. Plugin hooks (AIAST extensions)

| Mechanism | Authority | Companion |
|-----------|-----------|-----------|
| `PLUGIN_CONTRACT.md` hook points | `bootstrap.pre_flight`, `validation.report`, `ci.pre_commit`, etc. | `_system/plugins/<name>/plugin.json`, optional `run.sh` |
| `bootstrap/discover-plugins.sh` | Inventory | Plugin manifests |

## 4. Validation and doctor hooks

| Trigger | When | Companion |
|---------|------|-----------|
| `bootstrap/system-doctor.sh` | Health / drift / swarm / MCP checks | `PROJECT_PROFILE.md` validation expectations |
| `bootstrap/validate-system.sh` | Strict install integrity | |
| `bootstrap/check-runtime-foundations.sh` | Packaging / install / mobile scaffolds | |
| `bootstrap/check-evidence-quality.sh` | Handoff honesty | `HANDOFF_PROTOCOL.md` |
| `bootstrap/check-working-file-staleness.sh` | Planning file freshness | |

## 5. Git and GitHub automation hooks

| Surface | Purpose | Companion |
|---------|---------|-----------|
| **Git discipline** | Branch, push, merge readiness | `_system/GIT_REMOTE_AND_SYNC_PROTOCOL.md` |
| **GitHub Actions** `.github/workflows/*.yml` | CI/CD | Examples: `_system/ci/github-actions/*.example`; keep secrets out of YAML |
| **Copilot instructions** | Inline assistant load order | `.github/copilot-instructions.md` |
| **PR / merge checks** | Before merging: CI green, conflicts resolved, handoff updated | `WHERE_LEFT_OFF.md`, `TODO.md` |
| **PR / issue templates** | `.github/pull_request_template.md`, `.github/ISSUE_TEMPLATE/*` | Keep aligned with `VALIDATION_GATES.md` and `AGENTS.md`; ship with template so downstream repos inherit merge discipline |
| **MCP GitHub** | Issues, PRs, Actions from IDE | `_system/MCP_CONFIG.md` — `@modelcontextprotocol/server-github` |

**Merge readiness (sub-agent or dedicated role):** Confirm branch is up to date with
base, `git status` clean or documented, required checks described in
`PROJECT_PROFILE.md` or repo docs, and no instruction conflicts from parallel
agents. Use `.cursor/agents/github-ops.md` when delegating this lane in Cursor.

## 6. MCP as integration hooks

MCP servers are **optional accelerators** with policy in `_system/MCP_CONFIG.md`.
Adding or changing MCP usage should:

- Stay least-privilege (tokens scoped, read-only where possible).
- Cross-reference `MCP_SURVIVAL_PLAYBOOK.md` for failures.
- Not become a hard dependency for core build/test (see `MCP_CONFIG.md`).

## 7. Meta-system (MOS / master repo) note

Evolving **MOS** or **master meta workspace** (`_META_AGENT_SYSTEM/`) may use the
same hook patterns (prompt packs, factory lanes, meta-doctor). Read
`_META_AGENT_SYSTEM/HOOK_SUBAGENT_AND_META_STRATEGY.md` in the master repo for
boundaries and when sub-agents or MCP help without creating duplicate authority.

## Anti-patterns

- Adding a Cursor rule without checking for conflicts with `INSTRUCTION_PRECEDENCE_CONTRACT.md`.
- Duplicating full `AGENTS.md` bodies into Copilot or MCP prompts.
- Letting GitHub Actions bypass validation that `VALIDATION_GATES.md` requires locally.
