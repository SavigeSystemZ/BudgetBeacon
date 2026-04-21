# Integration Surfaces

Record external systems, APIs, providers, pipelines, and contracts that materially affect implementation.

## Entry format

- Surface:
- Type:
- Purpose:
- Contract or dependency:
- Failure mode:
- Fallback:
- Notes:

## Entries

- Surface: tool-adapter overlays (`AGENTS.md`, `CODEX.md`, `CLAUDE.md`, `GEMINI.md`, `WINDSURF.md`, Cursor, Copilot)
  Type: instruction-ingestion surface
  Purpose: translate repo-local canonical behavior into tool-specific starting context
  Contract or dependency: `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`, `_system/LOAD_ORDER.md`, `_system/REPO_OPERATING_PROFILE.md`, `_system/PROMPT_EMISSION_CONTRACT.md`
  Failure mode: duplicated authority claims, drift, or tool-specific overrides that silently contradict repo-local truth
  Fallback: `bootstrap/detect-instruction-conflicts.sh --strict` plus routing wording back to canonical files
  Notes: overlays should remain thin and referential

- Surface: operating-profile outputs
  Type: human/machine ingress artifact
  Purpose: give upstream hosts and maintainers one compact summary of canonical files, load order, validation, and packaging/install expectations
  Contract or dependency: `bootstrap/generate-operating-profile.sh`, `_system/REPO_OPERATING_PROFILE.md`, `_system/repo-operating-profile.json`
  Failure mode: drift from canonical docs after managed writes
  Fallback: regeneration in managed flows plus `--check` validation
  Notes: not intended to replace canonical docs, only to summarize them deterministically

- Surface: generated runtime foundations
  Type: repo bootstrap/runtime scaffold
  Purpose: provide installers, packaging manifests, env scaffolds, mobile stubs, AI config, and service-oriented runtime surfaces in generated repos
  Contract or dependency: `bootstrap/generate-runtime-foundations.sh` and `bootstrap/templates/runtime/`
  Failure mode: source-template files look correct but runtime behavior is unproven
  Fallback: presence validation today, executable smoke in future work
  Notes: runtime scaffolds must remain independent from `_system/`
