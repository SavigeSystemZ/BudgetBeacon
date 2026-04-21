# Host Bundle Contract

This contract defines how AIAST exports a self-contained prompt-and-context bundle for external hosts or orchestrators that cannot read repo-local paths directly.

## Purpose

- Preserve the same startup preamble and precedence model used by `bootstrap/emit-host-prompt.sh`.
- Export only the repo-local files required for the current task instead of inventing host-local truth.
- Keep external host consumption path-based, reviewable, and vendor-neutral.

## Required behavior

- Build bundle intent from `bootstrap/emit-host-prompt.sh` instead of re-deriving startup order ad hoc.
- Keep the canonical startup preamble unchanged.
- Export only relative repo paths.
- Include a deterministic load sequence with the startup files first.
- Include file-content snapshots plus hashes so an external consumer can validate what it loaded.
- State clearly that the bundle is a snapshot below repo-local truth, not a replacement for it.
- Keep runtime code independent from `_system/`.

## Required bundle fields

- `schema_version`
- `kind`
- `template_name`
- `template_version`
- `bundle_contract_path`
- `prompt_emission_contract_path`
- `operating_profile_path`
- `authority`
- `prompt_payload`
- `prompt_text`
- `load_sequence`
- `included_files`

## Included file rules

- `load_sequence` must start with the canonical startup files.
- `included_files` must use the same order as `load_sequence`.
- Each included file must carry its repo-relative path, `sha256`, line count, byte count, and text content.
- Do not include absolute paths, machine-local config, or hidden host-only instructions.
- Keep bundle scope narrow. Include only the additional repo-local files needed for the task.
- Prefer choosing scope from `_system/READ_BUNDLES.md` when one bundle already
  matches the task.

## Authority rules

- The bundle is an export surface for external use, not the source of truth.
- If the exported snapshot and the live repo later disagree, the live repo-local files still win.
- Host-added reporting or delivery requirements remain host-level orchestration context only.

## Maintenance path

1. Update `_system/PROMPT_EMISSION_CONTRACT.md` or related canonical docs first.
2. Update `bootstrap/emit-host-bundle.sh` or `bootstrap/check-host-bundle.sh` if the bundle contract changes.
3. Run `bootstrap/check-host-ingestion.sh <repo>`.
4. Run `bootstrap/check-host-bundle.sh <repo>`.
5. Run `bootstrap/validate-instruction-layer.sh <repo>`.

## Related files

- `_system/PROMPT_EMISSION_CONTRACT.md`
- `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`
- `_system/REPO_OPERATING_PROFILE.md`
- `_system/READ_BUNDLES.md`
- `_system/aiaast-capabilities.json`
- `bootstrap/emit-host-prompt.sh`
- `bootstrap/check-host-ingestion.sh`
- `bootstrap/emit-host-bundle.sh`
- `bootstrap/check-host-bundle.sh`
