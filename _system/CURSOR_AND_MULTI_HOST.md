# Cursor And Multi Host

This guide covers repos that are used from Cursor plus one or more additional
hosts such as Windsurf, Codex, Claude Code, Gemini CLI, or a custom external
orchestrator.

## Goal

Keep one repo-local source of truth even when several hosts can open or prompt
the same repository.

## Rules

- `AGENTS.md` is the shared entry contract.
- `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md` decides how host-level context
  loses to repo-local truth when they conflict.
- `.cursor/` overlays are allowed to improve Cursor-family UX, but they must not
  redefine project rules, product truth, or approval boundaries.
- If an external host cannot read repo-local paths directly, emit a host bundle
  instead of copying large prompt bodies by hand.

## Safe operating pattern

1. Keep repo-wide rules in `AGENTS.md` and `_system/`.
2. Keep Cursor-specific UX in `.cursor/`.
3. Keep host-generated prompt shims aligned through
   `bootstrap/generate-host-adapters.sh`.
4. Validate prompt-emission surfaces with
   `bootstrap/validate-instruction-layer.sh`.

## When to load this file

- the repo is being used from more than one IDE host
- a host-specific overlay is being added or edited
- prompt-export, host-bundle, or adapter behavior is changing

## Anti-patterns

- duplicating repo rules into several host-local prompt surfaces
- treating one IDE host as more authoritative than `AGENTS.md`
- storing product truth or sensitive data under `.cursor/`
