# Compress context (opt-in input file compression)

Use for **long human-edited prose** under `docs/` or `notes/` when tiered loading is not enough. This uses **Caveman-style input compression** via upstream [caveman-compress](https://github.com/JuliusBrussee/caveman/tree/main/caveman-compress) (wrapped by `bootstrap/compress-context-file.sh`). It is **not** `/concise-session` (that shortens **assistant output** via `concise-communication`).

## How this subsystem works

1. **AIAST wrapper** (`compress-context-file.sh`): enforces **v1 allowlist** (`docs/`, `notes/` only), file extension, basename denylist (no adapter filenames), and prefix denylist (no `_system/`, `bootstrap/`, `.cursor/`, etc.). Supports **`--dry-run`** (no writes). Refuses running as root for the real compress step.
2. **Upstream caveman-compress** (installed under `~/.claude/skills/caveman-compress`, **`CAVEMAN_COMPRESS_HOME`**, or master-repo **`_TEMPLATE_FACTORY/third_party/caveman-compress`**): run as  
   `PYTHONPATH=<skill-root> python3 -m scripts <absolute-path>`.  
   That pipeline calls **`claude --print`** to rewrite natural language, keeps code blocks and URLs intact, writes **`*.original.md`**, validates, and restores on failure.
3. **Dependencies:** **`claude`** (Anthropic Claude Code CLI) on **`PATH`** is **required** for actual compression; without it, the wrapper prints install hints and exits non-zero.

## When to use

- User explicitly wants shorter **files on disk** to save **input** context, and the file is **only** under `docs/` or `notes/`.
- **After** trying `bootstrap/emit-tiered-context.sh` and loading fewer governance files (`CONTEXT_BUDGET_STRATEGY.md`).
- Never for generated adapters, `validate-system` contract surfaces, or `_system/` bodies.

## Commands (what to run)

**Cursor:** type **`/compress-context`** in chat, then give the repo root and relative path (e.g. `docs/ARCHITECTURE_NOTES.md`).

**Shell (from repo root):**
```bash
./bootstrap/compress-context-file.sh . docs/YOURFILE.md --dry-run
./bootstrap/compress-context-file.sh . docs/YOURFILE.md
```
Use `notes/YOURFILE.md` when appropriate.

## Steps (agent checklist)

1. Confirm **repo root** and **relative path** under `docs/` or `notes/` only. Refuse governance/generated targets — see `_system/CONTEXT_BUDGET_STRATEGY.md` (input compression section).
2. Run **dry-run** (see shell above).
3. If the user confirms, run **without** `--dry-run` (non-root, `claude` + caveman-compress available).
4. After success:
   - `./bootstrap/validate-system.sh . --strict`
   - `./bootstrap/check-system-awareness.sh .`
   - Human **diff review**; rollback with `git checkout -- <path>` or **`*.original.md`** if code fences, paths, or URLs drift.

## Optional user prefix

Users may write `compress-context:` before their path; treat the path the same as an explicit argument.

## If something fails

- **`REFUSED`** or path errors → `_system/TROUBLESHOOTING.md` → section **compress-context-file refuses my path or will not run**.
- Procedural mirror: `.cursor/skills/compress-context-input/SKILL.md`.
