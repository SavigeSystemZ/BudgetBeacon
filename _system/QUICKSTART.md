# AIAST Quick Start

Get up and running with the AI Agent System Template in 5 minutes.

## What is AIAST?

AIAST is a project-local operating system for AI coding agents. It gives every agent (Claude, Codex, Cursor, Gemini, Windsurf, Copilot, DeepSeek, Aider, Cline, and more) the same rules, the same context, and a shared handoff protocol so they can work on your repo without stepping on each other.

Port and compose work: read `_system/ports/PORT_POLICY.md`. Governed allocation uses `registry/port_governance.yaml` and `python3 ops/install/lib/port_allocator.py` (stdlib-only helpers under `tools/`).

## Install into a new repo

```bash
# From the AIAST source template
bash TEMPLATE/bootstrap/scaffold-system.sh /path/to/your/repo --app-name "MyApp" --strict
```

Or use the interactive wizard:
```bash
bash TEMPLATE/bootstrap/wizard.sh /path/to/your/repo
```

## First steps after install

1. **Fill the project profile**: edit `_system/PROJECT_PROFILE.md` with your app's stack, validation commands, and deployment info.
2. **Choose a starter blueprint**: run `bootstrap/recommend-starter-blueprint.sh .` to get a recommendation, then `bootstrap/apply-starter-blueprint.sh . <blueprint>`.
3. **Run validation**: `bootstrap/validate-system.sh . --strict` to confirm everything is wired up.
4. **Start working**: open the repo in your preferred tool. It will load `AGENTS.md` and follow the shared rules automatically.

## How agents find the rules

For a **single map** of how the major `_system/` surfaces connect (review order, validation order, expansion paths), read `_system/SYSTEM_ORCHESTRATION_GUIDE.md`.

Every supported tool has an adapter file that points to `AGENTS.md`:

| Tool | Adapter file |
|------|-------------|
| Claude | `CLAUDE.md` |
| Codex | `CODEX.md` |
| Cursor | `.cursorrules` + `.cursor/` |
| Gemini | `GEMINI.md` |
| Windsurf | `WINDSURF.md` + `.windsurfrules` |
| Copilot | `.github/copilot-instructions.md` |
| DeepSeek | `DEEPSEEK.md` |
| Aider | `.aider.conf.yml` |
| Continue.dev | `.continuerules` |
| Cline | `.clinerules` |
| PearAI | `PEARAI.md` |
| Local models | `LOCAL_MODELS.md` |

## Key commands

| Command | Purpose |
|---------|---------|
| `bootstrap/scaffold-system.sh /path/to/repo --strict` | Auto-detect and install/sync safely |
| `bootstrap/validate-system.sh . --strict` | Verify system integrity |
| `bootstrap/system-doctor.sh .` | Run full health check |
| `bootstrap/system-doctor.sh . --heal` | Auto-repair issues |
| `bootstrap/check-environment.sh .` | Check runtime prerequisites |
| `bootstrap/discover-plugins.sh .` | List installed plugins |
| `bootstrap/emit-tiered-context.sh . --tier B` | Get context load for smaller models |
| `bootstrap/compress-context-file.sh . docs/FILE.md --dry-run` | Opt-in check for Caveman-style **input** prose compression (allowlisted paths only) |
| Cursor **`/compress-context`** | Same workflow from chat; see `.cursor/commands/compress-context.md` |

## Where to look when something goes wrong

- **Agent ignores rules**: check `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`
- **Validation fails**: run `bootstrap/system-doctor.sh . --report`
- **Missing files after upgrade**: run `bootstrap/install-missing-files.sh .` (add `--skip-onboarding-seeds` if the repo already has real product framing and you must not rewrite brief or working-file seeds)
- **Agent hallucinates**: run `bootstrap/check-hallucination.sh .`
- **Full troubleshooting**: see `_system/TROUBLESHOOTING.md`
- **compress-context refuses a path**: see `_system/TROUBLESHOOTING.md` → *compress-context-file refuses my path or will not run*

## Key concepts

- **`_system/`** is the agent operating layer. Runtime code must not depend on it.
- **`AGENTS.md`** is the binding contract for every tool.
- **Repo-local truth wins** over host-level orchestration.
- **Single active writer** at a time to prevent conflicts.
- **Handoff files** (`WHERE_LEFT_OFF.md`, `TODO.md`, `FIXME.md`) keep context across sessions.
