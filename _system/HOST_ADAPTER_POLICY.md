# Host Adapter Policy

This policy governs the tool-specific adapter files that sit on top of the shared repo-local AIAST core.

## Purpose

- Keep all supported tool entry files aligned with `AGENTS.md`, `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`, and `_system/REPO_OPERATING_PROFILE.md`.
- Treat tool adapters as live host-consumption surfaces, not freehand prose islands.
- Reduce adapter drift by generating the highest-risk shared adapter files from one manifest instead of rewriting them independently.

## Canonical sources

- `AGENTS.md`
- `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`
- `_system/REPO_OPERATING_PROFILE.md`
- `_system/LOAD_ORDER.md`
- `_system/PROMPT_EMISSION_CONTRACT.md`
- `_system/host-adapter-manifest.json`

## Generated adapter surfaces

The following files are generated from `_system/host-adapter-manifest.json`:

- `CODEX.md`
- `CLAUDE.md`
- `GEMINI.md`
- `WINDSURF.md`
- `.cursorrules`
- `.windsurfrules`
- `.github/copilot-instructions.md`
- `.cursor/commands/load-context.md`
- `.cursor/commands/session-start.md`
- `.cursor/skills/load-context/SKILL.md`
- `.cursor/rules/00-context-load.mdc`

## Change rules

- Do not hand-edit generated adapter surfaces as the primary maintenance path.
- If the shared startup contract changes, update the canonical source docs and `_system/host-adapter-manifest.json`, then run `bootstrap/generate-host-adapters.sh <repo> --write`.
- Validate generated adapter alignment with `bootstrap/check-host-adapter-alignment.sh <repo>`.
- Run `bootstrap/validate-instruction-layer.sh <repo>` after changing adapter-generation logic, the manifest, or the shared precedence/emission contracts.

## Boundary rules

- Adapters may add tool-specific emphasis, but they must not override repo-local truth.
- Adapters must keep runtime code independent from `_system/`.
- Adapters should point back to canonical repo files instead of duplicating long rule bodies.
- Prefer generation only for stable startup, context-load, and authority overlays. Keep richer review commands, broader skills, and agent-specific workflow docs hand-authored unless real drift proves they need the same treatment.
- If a tool needs a different startup shape, add that variation to the manifest or generator instead of introducing unmanaged divergence.

## Maintenance path

1. Update shared source docs or `_system/host-adapter-manifest.json`.
2. Run `bootstrap/generate-host-adapters.sh <repo> --write`.
3. Run `bootstrap/check-host-adapter-alignment.sh <repo>`.
4. Run `bootstrap/validate-instruction-layer.sh <repo>`.
5. Regenerate system metadata if the repo is in a managed write flow.
