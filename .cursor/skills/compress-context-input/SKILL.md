---
name: compress-context-input
description: Opt-in checklist for Caveman-style input compression of human prose under docs/ or notes/ via bootstrap/compress-context-file.sh. Use when the user wants to shrink long markdown notes or runs /compress-context.
---

# Compress context input (opt-in)

**Not** for assistant output — use `concise-communication` / `/concise-session` for that.

## How it works (two layers)

- **AIAST:** `bootstrap/compress-context-file.sh` gates paths (allowlist `docs/` + `notes/`, deny dangerous trees and names), supports `--dry-run`, then delegates.
- **Upstream caveman-compress:** `PYTHONPATH=<skill-root> python3 -m scripts <file>` runs compression via **`claude --print`**, keeps code/URLs stable, writes **`*.original.md`**, validates, restores on hard failure. No `claude` → no compression.

**Invoke in Cursor:** user types **`/compress-context`** (this command loads the checklist: `.cursor/commands/compress-context.md`).

## Before

1. Confirm the path is **only** under `docs/` or `notes/` (relative to repo root) and is `.md`, `.txt`, or `.rst`.
2. **Refuse** `_system/`, `bootstrap/`, `.cursor/`, generated host adapter filenames, `AGENTS.md`, or contract-heavy trees — see `_system/CONTEXT_BUDGET_STRATEGY.md`.
3. Prefer **tiered loading** (`bootstrap/emit-tiered-context.sh`) first; compress only when appropriate.

## Run

```bash
./bootstrap/compress-context-file.sh . <relative-path> --dry-run
./bootstrap/compress-context-file.sh . <relative-path>
```

Requires: upstream `caveman-compress` (e.g. `CAVEMAN_COMPRESS_HOME` or `~/.claude/skills/caveman-compress`), and `claude` on `PATH`. Master AIAST repo: optional vendored copy under `_TEMPLATE_FACTORY/third_party/caveman-compress`.

## After

- `./bootstrap/validate-system.sh . --strict`
- `./bootstrap/check-system-awareness.sh .`
- Review diff; rollback with `git checkout -- <path>` or `*.original.md` backup if needed.
