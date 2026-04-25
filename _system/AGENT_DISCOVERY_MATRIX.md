# Agent Discovery Matrix

This file tells each supported tool which files it should load first, which adapter file belongs to it, which other adapter files exist, and what shared rules are authoritative.

Tool-entry files and shared load-context overlays are governed by `_system/HOST_ADAPTER_POLICY.md` and may be regenerated via `bootstrap/generate-host-adapters.sh`. Validate them with `bootstrap/check-host-adapter-alignment.sh`.

Canonical adapter classes, naming rules, and placeholder boundaries are defined in `_system/AGENT_SURFACE_TAXONOMY.md`. External initialization pattern ingestion is defined in `_system/AGENT_INIT_CONVERGENCE.md`.

External host exports are governed by `_system/HOST_BUNDLE_CONTRACT.md` and may be emitted via `bootstrap/emit-host-bundle.sh`. Validate them with `bootstrap/check-host-bundle.sh`.

## Orientation (optional)

When you need one checklist for how surfaces connect, review order, validation order, and where to expand the system:

- `_system/SYSTEM_ORCHESTRATION_GUIDE.md`

## Shared truth for every tool

Every tool must treat these as canonical:

- `AGENTS.md`
- `_system/PROJECT_PROFILE.md`
- `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`
- `_system/REPO_OPERATING_PROFILE.md`
- `_system/READ_BUNDLES.md`
- `_system/CONTEXT_INDEX.md`
- `_system/WORKING_FILES_GUIDE.md`
- `_system/TEMPLATE_NEUTRALITY_POLICY.md`
- `_system/MASTER_SYSTEM_PROMPT.md`
- `_system/PROJECT_RULES.md`
- `_system/EXECUTION_PROTOCOL.md`
- `_system/MULTI_AGENT_COORDINATION.md`
- `_system/AGENT_ROLE_CATALOG.md`
- `PRODUCT_BRIEF.md`
- `TODO.md`
- `FIXME.md`
- `WHERE_LEFT_OFF.md`

## Shared working surfaces

Load these when the task touches their domain:

- `PLAN.md`
- `ROADMAP.md`
- `DESIGN_NOTES.md`
- `ARCHITECTURE_NOTES.md`
- `RESEARCH_NOTES.md`
- `TEST_STRATEGY.md`
- `RISK_REGISTER.md`
- `RELEASE_NOTES.md`
- `_system/context/ASSUMPTIONS.md`
- `_system/context/INTEGRATION_SURFACES.md`

## Governance add-ons

Load these when the task changes installable AIAST behavior, recovery behavior,
or current-state tooling assumptions:

- `_system/TEMPLATE_CHANGE_IMPACT_POLICY.md`
- `_system/SELF_HEALING_BOUNDARY.md`
- `_system/VERSION_SENSITIVE_RESEARCH_PROTOCOL.md`
- `_system/WORKSPACE_AUTHORITY_AND_CONTAINMENT_PROTOCOL.md`
- `_system/PROJECT_IDENTITY_AND_SCOPE_PROTOCOL.md`
- `_system/GLOBAL_REDIRECT_SHIM_POLICY.md`
- `_system/SCAVENGE_AND_DISCOVERY_AUTHORIZATION.md`
- `_system/SESSION_ENVIRONMENT_REPORT_CONTRACT.md`
- `_system/ORPHAN_META_SNAPSHOT_POLICY.md`

## Golden example pack

Load these when creating or materially rewriting working files, prompt packs, skills, MCP policy docs, or core system surfaces:

- `_system/GOLDEN_EXAMPLES_POLICY.md`
- `_system/golden-examples/PATTERN_INDEX.md`
- the relevant files under `_system/golden-examples/patterns/`
- the relevant files under `_system/golden-examples/working-files/`

## Delegation and roles

Load `_system/AGENT_ROLE_CATALOG.md` whenever work is being split across roles, tools, reviewers, or validators.

## Codex

- Primary adapter: `CODEX.md`
- Shared repo contract: `AGENTS.md`
- Tool-specific overlay: none beyond `CODEX.md`
- Must know these also exist: `CLAUDE.md`, `GEMINI.md`, `WINDSURF.md`, `.cursorrules`, `.github/copilot-instructions.md`
- Best use: precise implementation, repair, review, diff-heavy work

## Cursor

- Primary adapter: `.cursorrules`
- Secondary adapter surface: `.cursor/`
- Shared repo contract: `AGENTS.md`
- Must know these also exist: `CODEX.md`, `CLAUDE.md`, `GEMINI.md`, `WINDSURF.md`, `.github/copilot-instructions.md`
- Best use: file-aware navigation, command-driven workflows, skills, reusable rules

## Claude

- Primary adapter: `CLAUDE.md`
- Shared repo contract: `AGENTS.md`
- Must know these also exist: `CODEX.md`, `GEMINI.md`, `WINDSURF.md`, `.cursorrules`, `.github/copilot-instructions.md`
- Best use: architecture, design reasoning, policy review, long-context synthesis

## Gemini

- Primary adapter: `GEMINI.md`
- Shared repo contract: `AGENTS.md`
- Must know these also exist: `CODEX.md`, `CLAUDE.md`, `WINDSURF.md`, `.cursorrules`, `.github/copilot-instructions.md`
- Best use: whole-repo analysis (Tier S), cross-cutting architectural refactors, deep codebase investigations, multimodal verification, design critique, and long-form planning.

## Windsurf

- Primary adapter: `WINDSURF.md`
- Secondary adapter: `.windsurfrules`
- Shared repo contract: `AGENTS.md`
- Must know these also exist: `CODEX.md`, `CLAUDE.md`, `GEMINI.md`, `.cursorrules`, `.github/copilot-instructions.md`
- Best use: IDE-based implementation and repo navigation under the shared rules

## Copilot

- Primary adapter: `.github/copilot-instructions.md`
- Shared repo contract: `AGENTS.md`
- Must know these also exist: `CODEX.md`, `CLAUDE.md`, `GEMINI.md`, `WINDSURF.md`, `.cursorrules`
- When touching **GitHub Actions, workflows, or PR/merge** work, also load `_system/HOOK_AND_ORCHESTRATION_INDEX.md` and `_system/GIT_REMOTE_AND_SYNC_PROTOCOL.md`
- Best use: inline assistance under the same operating rules; pair with **GitHub / CI steward** role when CI is the main task

## DeepSeek

- Primary adapter: `DEEPSEEK.md`
- Shared repo contract: `AGENTS.md`
- Must know these also exist: `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `WINDSURF.md`, `.cursorrules`, `.github/copilot-instructions.md`, `.aider.conf.yml`, `.continuerules`, `.clinerules`, `PEARAI.md`, `LOCAL_MODELS.md`
- Best use: code generation, implementation, debugging; strong at code-heavy tasks with large context

## Aider

- Primary adapter: `.aider.conf.yml`
- Shared repo contract: `AGENTS.md`
- Must know these also exist: `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `DEEPSEEK.md`, `WINDSURF.md`, `.cursorrules`, `.github/copilot-instructions.md`
- Best use: precise file-level edits, multi-file refactors, CLI-driven pair programming

## Continue.dev

- Primary adapter: `.continuerules`
- Shared repo contract: `AGENTS.md`
- Must know these also exist: `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `DEEPSEEK.md`, `WINDSURF.md`, `.cursorrules`, `.github/copilot-instructions.md`
- Best use: IDE-integrated autocomplete, chat, and inline edits under the shared rules

## Cline

- Primary adapter: `.clinerules`
- Shared repo contract: `AGENTS.md`
- Must know these also exist: `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `DEEPSEEK.md`, `WINDSURF.md`, `.cursorrules`, `.github/copilot-instructions.md`
- Best use: autonomous multi-step implementation, terminal-aware workflows, file creation

## PearAI

- Primary adapter: `PEARAI.md`
- Shared repo contract: `AGENTS.md`
- Must know these also exist: `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `DEEPSEEK.md`, `WINDSURF.md`, `.cursorrules`, `.github/copilot-instructions.md`
- Best use: IDE-based implementation and code exploration under the shared rules

## Local Models (Ollama / LLaMA / Mistral)

- Primary adapter: `LOCAL_MODELS.md`
- Shared repo contract: `AGENTS.md`
- Must know these also exist: all other adapter files
- Context budget: consult `_system/CONTEXT_BUDGET_STRATEGY.md` for tiered loading
- Best use: offline or privacy-sensitive work under the same operating rules; use fast-path loading for smaller models

## Hook surfaces and orchestration (every tool)

- Master index: `_system/HOOK_AND_ORCHESTRATION_INDEX.md` (Cursor rules/commands/skills/agents, plugins, validation doctors, GitHub/CI, MCP)
- Cursor delegated agents include `github-ops.md` for CI/merge slices; command: `.cursor/commands/github-session.md`
- Regenerate root adapters after contract changes: `bootstrap/generate-host-adapters.sh`

## Unknown or future agent

- Fallback load path:
  1. `AGENTS.md`
  2. `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`
  3. `_system/REPO_OPERATING_PROFILE.md`
  4. `_system/CONTEXT_INDEX.md`
  5. `_system/SYSTEM_ORCHESTRATION_GUIDE.md` (optional orientation)
  6. `_system/LOAD_ORDER.md`
  7. `_system/WORKING_FILES_GUIDE.md`
  8. `_system/MASTER_SYSTEM_PROMPT.md`
  9. `_system/AGENT_ROLE_CATALOG.md`
  10. `PRODUCT_BRIEF.md`
  11. `TODO.md`
  12. `FIXME.md`
  13. `WHERE_LEFT_OFF.md`

## Coexistence rule

No adapter may contradict the shared core. If an adapter needs a different emphasis, it may add tool-specific handling only on top of the shared rules.

Compatibility placeholders (`CURSOR.md`, `COPILOT.md`, `AIDER.md`, `AGENT_ZERO.md`) exist for cross-agent scaffold comparability and must remain thin pointer surfaces.

When a host/orchestrator layer exists, it must defer to repo-local truth and the precedence contract rather than redefining the shared core.

If an external host cannot read repo paths directly, export a narrow host bundle instead of copying large rule bodies into host-local prompts.
