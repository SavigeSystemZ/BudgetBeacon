# Agent Surface Taxonomy

This contract defines the canonical file taxonomy for multi-agent entry surfaces in AIAST-installed repositories.

It standardizes where shared governance lives, how adapter files are named, and how optional placeholders stay comparable across tools without fragmenting policy.

## Goals

- Keep one shared source of truth for governance.
- Keep adapter files thin and pointer-oriented.
- Keep placeholder coverage broad enough for cross-agent scaffolding.
- Avoid silent drift between prose contracts, manifests, and generated files.

## Surface Classes

### Class A: Shared Governance (authoritative)

These files define shared repo authority and apply to all tools:

- `AGENTS.md`
- `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`
- `_system/REPO_OPERATING_PROFILE.md`
- `_system/LOAD_ORDER.md`
- `_system/MULTI_AGENT_COORDINATION.md`
- `_system/AGENT_DISCOVERY_MATRIX.md`

If a Class C or Class D surface conflicts with Class A, Class A wins.

### Class B: Generation and Validation Controls

These files control adapter generation and alignment checks:

- `_system/HOST_ADAPTER_POLICY.md`
- `_system/host-adapter-manifest.json`
- `bootstrap/generate-host-adapters.sh`
- `bootstrap/check-host-adapter-alignment.sh`

Class B is enforcement infrastructure, not policy authority.

### Class C: Generated Primary Adapters

These are generated from `_system/host-adapter-manifest.json` and must not be hand-maintained as a primary path:

- `CODEX.md`
- `CLAUDE.md`
- `GEMINI.md`
- `WINDSURF.md`
- `DEEPSEEK.md`
- `PEARAI.md`
- `LOCAL_MODELS.md`
- `.cursorrules`
- `.windsurfrules`
- `.github/copilot-instructions.md`
- `.aider.conf.yml`
- `.continuerules`
- `.clinerules`
- `.cursor/commands/load-context.md`
- `.cursor/commands/session-start.md`
- `.cursor/skills/load-context/SKILL.md`
- `.cursor/rules/00-context-load.mdc`

### Class D: Optional Placeholder Adapters (human-authored)

These are intentionally lightweight compatibility placeholders. They must point to Class A contracts and must not redefine policy:

- `CURSOR.md`
- `COPILOT.md`
- `AIDER.md`
- `AGENT_ZERO.md`
- `CASCADE.md` (optional if the host is in active use)

### Class E: Deprecated or Alias Surfaces

Aliases are allowed only as transition compatibility surfaces. They must contain pointer text and deprecation notes, not divergent policy.

Current canonical aliases and compatibility mappings are tracked in `_system/host-adapter-manifest.json` under `deprecated_aliases`.

## Naming Standard

- Preferred naming for top-level adapter docs: uppercase snake-like labels with `.md` suffix (`CODEX.md`, `AGENT_ZERO.md`).
- Dot-rule files (`.cursorrules`, `.windsurfrules`, `.continuerules`, `.clinerules`) remain exact because tools require them.
- Generated adapters must be represented in the manifest using stable ids; paths are treated as API-like contract surfaces.

## Conflict and Merge Rules

- Shared governance updates are additive-first.
- Adapter-specific emphasis belongs in adapter files only if it does not collide with shared governance.
- Cross-tool patterns that apply to more than one adapter must be promoted into Class A files.
- When in doubt, prefer narrower adapter text that references shared contracts by path.

## Validation Requirements

After changing taxonomy, adapter naming, manifest paths, or adapter policy:

1. Run `bootstrap/generate-host-adapters.sh <repo> --write`.
2. Run `bootstrap/check-host-adapter-alignment.sh <repo>`.
3. Run `bootstrap/validate-instruction-layer.sh <repo>`.
4. Run `_TEMPLATE_FACTORY/validate-master-template.sh` before release claims.

## Downstream Safety Rule

Changes to this taxonomy must be additive-first unless a deprecation window and migration notes are included in:

- `CHANGELOG.md`
- `RELEASE_NOTES.md`
- `_system/MIGRATION_GUIDE.md`
