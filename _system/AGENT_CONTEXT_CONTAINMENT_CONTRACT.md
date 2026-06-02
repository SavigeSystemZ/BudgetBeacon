# Agent Context Containment Contract

This contract defines which contexts must stay repo-local and prohibits parent-directory context leakage.

## Authority principle

**Each repository has exactly one source of truth for agent context: its own local `AGENTS.md`, `_system/`, and tool-specific adapter folders.**

- Parent directories (e.g., `~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/`) are redirect shims only.
- Agents must load from the working directory's authority, not from parent directories.
- Context stored in parent-level adapter folders (e.g., `~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/.cursor/plans/`) does NOT apply to child repos.

## Context categories and containment

### Category 1: Governance and Operating Layer (MUST stay repo-local)

These files define how agents operate and must not be inherited from parent directories:

- `AGENTS.md` — Agent rules, load order, operating contracts.
- `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md` — Load order resolution.
- `_system/REPO_OPERATING_PROFILE.md` — Repo-specific operating mode.
- `_system/PROJECT_PROFILE.md` — Project identity and scope.
- `_system/MASTER_SYSTEM_PROMPT.md` — Meta-system doctrine.
- `_system/EXECUTION_PROTOCOL.md` — Execution discipline.
- `_system/VALIDATION_GATES.md` — Validation discipline.
- All other files in `_system/` directory.

**Enforcement:** Agents MUST load these from the working directory first. If not found, report missing and ask operator to scaffold the repo.

### Category 2: Project-Specific Planning (MUST stay repo-local)

These files document project-specific work and must not bleed across repos:

- `PRODUCT_BRIEF.md` — What the project builds.
- `DESIGN_NOTES.md` — Design decisions for this project.
- `ARCHITECTURE_NOTES.md` — Architecture decisions for this project.
- `RESEARCH_NOTES.md` — Research findings for this project.
- `WHERE_LEFT_OFF.md` — Handoff state for this project.
- `TODO.md` — Project-specific work items.
- `FIXME.md` — Project-specific defects.
- `PLAN.md` — Current plan for this project.
- `ROADMAP.md` — Project roadmap.

**Enforcement:** Each repo maintains separate copies. Agents MUST NOT read these from parent directories.

### Category 3: Tool-Specific Context (MUST stay repo-local)

Tool-specific adapter folders contain context and configuration that must be isolated per repo:

- `.claude/` — Claude-specific context (settings, plans, rules).
- `.cursor/` — Cursor-specific context (plans, rules, settings).
- `.gemini/` — Gemini-specific context.
- `.aider/` — Aider-specific context.
- `.continuerules/` — Continue.dev-specific rules.
- `.clinerules/` — Cline-specific rules.
- `.github/copilot-config.aiaast.json` — Copilot-specific config.

**Containment rules:**

- Each repo has its own isolated `.claude/`, `.cursor/`, etc. directories.
- Parent-directory adapter folders (e.g., `~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/.cursor/`) are **redirect shims only**, containing no project-specific plans or context.
- Redirect shims point agents to the working directory's local adapter folder.
- Agents MUST NOT read context from parent-directory adapter folders.
- Each repo's adapter folder is writable and independent.

**Examples:**

```text
CORRECT:  ~/.MyAppZ/my-app/.cursor/plans/              ← Use this for my-app context
WRONG:    ~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/.cursor/ ← Do NOT use this for my-app

CORRECT:  ~/.MyAppZ/my-app/WHERE_LEFT_OFF.md           ← Use this for my-app handoff
WRONG:    ~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/WHERE_LEFT_OFF.md  ← Do NOT use this
```

### Category 4: Runtime Application Code (MUST NOT depend on `_system/`)

Application code must not depend on or reference files in the `_system/` directory:

- `src/`, `app/`, `lib/`, etc. must be fully independent.
- No code should `require()`, `import`, or reference `_system/` files at runtime.
- `_system/` is an agent operating layer only; it does not ship with the application.

**Enforcement:** Linters and deployment validators MUST flag any code that references `_system/`.

## Redirect shim specification

Root-level adapter folders (in parent directories) may exist as redirect shims:

### Structure

```
~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/.cursor/
├── README.md                    ← Redirect notice (required)
├── .gitignore                   ← Standard (optional)
└── [NO plans/, rules/, context]
```

### Content

- **Redirect notice (README.md):** Clearly states this is a shim, points to local-repo authority.
- **No embedded context:** Shims MUST NOT contain project-specific plans, rules, or settings.
- **No hardcoded paths:** Shims MUST NOT reference specific directories (e.g., "Canonical PWD: ...").
- **Minimal content:** Shims are thin routing stubs only.

### Loading behavior

When an agent finds a parent-directory adapter file (e.g., `.cursor/README.md`):

1. Read the redirect notice.
2. Understand that the active context lives in the working directory's copy.
3. Load from `~/.MyAppZ/<ProjectName>/.cursor/` instead.
4. If the working-directory copy doesn't exist, create it or ask the operator.

## Isolation gates and validation

### Preflight checks

Before starting work, agents MUST verify:

1. **Authority source**: `AGENTS.md` and `_system/` exist in the working directory.
2. **No parent-context leakage**: Confirm that planning context comes from local `.cursor/`, `.claude/`, etc., not from parent directories.
3. **Project identity**: Read `_system/.aiast-role.json` to confirm the repo type (downstream-app vs parent-template).

Script: `bootstrap/check-context-isolation.sh`

### Validation rules

```bash
# PASS: Local AGENTS.md exists
test -f ./AGENTS.md && echo "✓ Local AGENTS.md found"

# FAIL: Context loaded from parent directory
if grep -r "~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE" .cursor/plans/ 2>/dev/null; then
    echo "✗ VIOLATION: Found parent-directory references in .cursor/plans/"
    exit 1
fi

# FAIL: .cursor/ folder inherited from parent (should be copy + modifications)
if [ -L .cursor ]; then
    echo "✗ VIOLATION: .cursor is a symlink to parent directory"
    exit 1
fi
```

### Failed checks

If isolation checks fail:

1. Stop agent work immediately.
2. Report the isolation violation to the operator.
3. Provide remediation steps:
   - Copy the working-directory adapter folder from a clean install (if needed).
   - Remove symlinks to parent directories.
   - Delete inherited context files.
4. Re-validate before resuming work.

## Special cases and exceptions

### Template maintainer mode

When working inside the `_AI_AGENT_SYSTEM_TEMPLATE/` source repo:

- Parent-level adapter folders may contain template-maintenance context.
- These are located in `_META_AGENT_SYSTEM/` (not root adapter folders).
- App repos NEVER see `_META_AGENT_SYSTEM/` content (it stays source-repo-only).

### Downstream repo setup

When a new downstream app repo is scaffolded:

- `bootstrap/install-aiast.sh` creates local `AGENTS.md`, `_system/`, and tool adapters.
- New `.cursor/`, `.claude/`, etc. folders are empty by default (ready for agent-specific context).
- The operator or agent populates these as needed during development.

### Cross-repo scavenging (rare)

If an agent needs to inspect a sibling repo for pattern comparison:

- **Read-only inspection** of `_system/`, `AGENTS.md`, and design docs is permitted.
- **Forbidden:** Copying project-specific plans or context into the working repo.
- **Forbidden:** Writing to sibling repo directories.
- **Report:** Document the scavenged patterns in a local research note, not by copying files.

## Maintainer discipline

In the master `_AI_AGENT_SYSTEM_TEMPLATE/` repo:

- Avoid putting app-building context into root adapter folders.
- Use `_META_AGENT_SYSTEM/` for template-maintenance planning and coordination.
- Keep `TEMPLATE/` repo-neutral so fresh downstream installs don't inherit stale context.
- When updating `TEMPLATE/` docs or rules, ensure they don't assume project-specific context.

## Summary

| Context Type | Storage | Load Source | Inheritance |
| --- | --- | --- | --- |
| Governance (`AGENTS.md`, `_system/`) | Repo-local | Working directory | ❌ No parent fallback |
| Project planning (PRODUCT_BRIEF, TODO, etc.) | Repo-local | Working directory | ❌ No parent fallback |
| Tool context (`.cursor/`, `.claude/`, etc.) | Repo-local | Working directory | ⚠️ Only redirect shims from parent |
| Template maintenance planning | `_META_AGENT_SYSTEM/` | Master repo only | ❌ Never in downstream copies |
| Application code | Repo-local | Runtime | ❌ Never references `_system/` |

---

**Enforcement date:** Effective immediately for all new scaffolds and meta-sync sessions.
**Retrofit:** Existing downstream repos must pass `check-context-isolation.sh` to remain in compliance.
