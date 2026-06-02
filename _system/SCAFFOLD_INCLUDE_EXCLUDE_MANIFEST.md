# Scaffold Include/Exclude Manifest

This contract defines how AIAST chooses files for downstream scaffolds.
The machine-readable source is `_system/scaffold-profiles.json`.

## Authority

- `TEMPLATE/` remains the only normal app scaffold source.
- Parent-template layers are not app scaffold inputs:
  - `_META_AGENT_SYSTEM/`
  - `_TEMPLATE_FACTORY/`
  - `_MOS_TEMPLATE_FACTORY/`
  - `MOS_TEMPLATE/`
  - `MOS_SOURCE_LIBRARY/`
- `meta-system-development` is a maintainer profile, but it does not make
  app scaffolding copy parent source-repo layers. MOS installation must use the
  MOS bootstrap path.

## Profile Semantics

Profiles are policy overlays, not alternate source roots. A profile defines:

- include patterns
- exclude patterns
- required files
- optional files
- generated files
- forbidden downstream paths
- required validators

The current hardened default keeps the full installable AIAST operating layer
for every supported profile so existing strict validation remains meaningful.
Profile-specific narrowing can happen only after that narrowed profile has its
own strict validator and benchmark evidence.

## Required Exclusions

Every non-MOS app scaffold must exclude:

- `.env` files except explicit examples
- secrets directories
- VCS internals
- dependency caches and virtual environments
- parent-template maintainer layers
- MOS source/product layers unless using MOS bootstrap directly
- resolved MCP paths, tokens, database URLs, browser profiles, memory stores,
  or cache roots that point outside the current app boundary

## Runtime Boundary

Runtime app code belongs outside `_system/`. `_system/` is governance,
validation, context, and adapter authority. Runtime foundations are emitted
from `bootstrap/templates/runtime/` into app-facing directories such as `ops/`,
`registry/`, `tools/`, `mobile/`, `ai/`, `packaging/`, and `distribution/`.

## Enforcement

- `bootstrap/render-scaffold-profile.sh`
- `bootstrap/validate-scaffold-output.sh`
- `bootstrap/check-scaffold-required-files.sh`
- `bootstrap/check-mos-downstream-exclusion.sh`
- `bootstrap/check-mcp-project-isolation.sh`
- `bootstrap/validate-scaffold-profile.sh`
- `bootstrap/validate-scaffold-profiles.sh`
