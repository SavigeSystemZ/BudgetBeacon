# Repo Operating Profile

## Summary
- Template: `AIAST` `1.23.0`
- Profile state: `configured-project`
- System README path: `README.md`
- Ingestion start: `AGENTS.md` -> `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md` -> `_system/REPO_OPERATING_PROFILE.md` -> `_system/LOAD_ORDER.md`

## Canonical instruction files
- `AGENTS.md`
- `_system/PROJECT_PROFILE.md`
- `_system/PROJECT_DOMAIN_MANIFEST.json`
- `_system/INSTRUCTION_DOMAIN_ALIGNMENT_PROTOCOL.md`
- `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`
- `_system/REPO_OPERATING_PROFILE.md`
- `_system/LOAD_ORDER.md`
- `_system/MASTER_SYSTEM_PROMPT.md`
- `_system/PROJECT_RULES.md`
- `_system/AGENT_ROLE_CATALOG.md`
- `_system/AGENT_DISCOVERY_MATRIX.md`

## Load order anchor
1. `AGENTS.md`
2. `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`
3. `_system/REPO_OPERATING_PROFILE.md`
4. `_system/PROJECT_PROFILE.md`
5. `_system/CONTEXT_INDEX.md`
6. `_system/LOAD_ORDER.md`

## Bundle model
- Read bundles contract: `_system/READ_BUNDLES.md`
- Preferred bundle ids: `template-evolution, repo-onboarding, runtime-foundations, packaging-distribution, adapter-host-emission, release-readiness, repo-pivot`

## Terminology mappings
- `host-level-orchestration-context`: Task framing or operator intent emitted outside the repo.
- `repo-local-truth`: Facts stored in repo-local runtime/config/docs and the authoritative AIAST core docs.
- `runtime-system-boundary`: Runtime code must remain independent from _system/.
- `tool-overlay`: A tool-specific adapter or rules layer that sits on top of the repo-local core.
- `workspace-authority`: For downstream repos, authority is the working-directory copy, not parent/global shims.

## Validation entrypoints
- `bootstrap/validate-system.sh <repo>`
- `bootstrap/check-install-boundary.sh <repo>`
- `bootstrap/validate-instruction-layer.sh <repo>`
- `bootstrap/check-host-adapter-alignment.sh <repo>`
- `bootstrap/check-host-ingestion.sh <repo>`
- `bootstrap/check-host-bundle.sh <repo>`
- `bootstrap/check-system-awareness.sh <repo>`
- `bootstrap/check-working-directory-alignment.sh <repo>`
- `bootstrap/check-project-target-consistency.sh <repo>`
- `bootstrap/check-global-shim-alignment.sh <repo>`
- `bootstrap/emit-session-environment.sh <repo>`
- `bootstrap/detect-instruction-conflicts.sh <repo> --strict`
- `bootstrap/system-doctor.sh <repo>`
- `bootstrap/check-packaging-targets.sh <repo>`

## Packaging / install expectations
- Runtime foundation generator: `bootstrap/generate-runtime-foundations.sh`
- Current runtime roots present: `packaging, ops, mobile, ai`
- Expected installer commands: `ops/install/install.sh, ops/install/repair.sh, ops/install/uninstall.sh, ops/install/purge.sh`
- Expected packaging manifests: `packaging/appimage.yml, packaging/flatpak-manifest.json, packaging/snapcraft.yaml`
- Expected mobile scaffold: `mobile/flutter`
- Expected AI config: `ai/llm_config.yaml`
- Default bind model: `127.0.0.1` or `::1`
- Default port range: `8000-9000`

## Boundaries and adapters
- Runtime/system boundary: runtime code must remain independent from `_system/`.
- Tool adapters present: `codex:CODEX.md, claude:CLAUDE.md, gemini:GEMINI.md, windsurf:WINDSURF.md, cursor:.cursorrules, copilot:.github/copilot-instructions.md`
- Precedence contract: `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md` + `_system/instruction-precedence.json`
- Prompt emission contract: `_system/PROMPT_EMISSION_CONTRACT.md`
- Change impact policy: `_system/TEMPLATE_CHANGE_IMPACT_POLICY.md`
- Self-healing boundary: `_system/SELF_HEALING_BOUNDARY.md`
- Version-sensitive research protocol: `_system/VERSION_SENSITIVE_RESEARCH_PROTOCOL.md`
- Workspace authority protocol: `_system/WORKSPACE_AUTHORITY_AND_CONTAINMENT_PROTOCOL.md`
- Project identity/scope protocol: `_system/PROJECT_IDENTITY_AND_SCOPE_PROTOCOL.md`
- Global redirect shim policy: `_system/GLOBAL_REDIRECT_SHIM_POLICY.md`
- Scavenge/discovery authorization: `_system/SCAVENGE_AND_DISCOVERY_AUTHORIZATION.md`
- Session environment report contract: `_system/SESSION_ENVIRONMENT_REPORT_CONTRACT.md`
- Orphan meta snapshot policy: `_system/ORPHAN_META_SNAPSHOT_POLICY.md`
- Host adapter generator: `bootstrap/generate-host-adapters.sh`
- Host adapter validator: `bootstrap/check-host-adapter-alignment.sh`
- Host adapter manifest: `_system/host-adapter-manifest.json`
- Host prompt emitter: `bootstrap/emit-host-prompt.sh`
- Host ingestion validator: `bootstrap/check-host-ingestion.sh`
- Host bundle contract: `_system/HOST_BUNDLE_CONTRACT.md`
- Host bundle emitter: `bootstrap/emit-host-bundle.sh`
- Host bundle validator: `bootstrap/check-host-bundle.sh`

## Golden examples
- Golden example policy: `_system/GOLDEN_EXAMPLES_POLICY.md`
- Pattern index: `_system/golden-examples/PATTERN_INDEX.md`
- Manifest: `_system/golden-examples/golden-example-manifest.json`

## Version and compatibility markers
- Human-readable version: `AIAST_VERSION.md`
- Installed version marker: `_system/.template-version`
- Capabilities manifest: `_system/aiaast-capabilities.json`
- Operating profile JSON: `_system/repo-operating-profile.json`
