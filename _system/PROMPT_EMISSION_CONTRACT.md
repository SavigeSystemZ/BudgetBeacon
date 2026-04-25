# Prompt Emission Contract

This contract defines how AIAST prompt templates and prompt packs must be emitted when they are handed to external coding tools or host/orchestrator systems.

## Required behavior

- Tell the target tool to load repo-local instruction files first.
- Distinguish host-level orchestration context from repo-local truth.
- Reference canonical repo files by path instead of copying long rule bodies.
- Resolve ambiguity in favor of repo-local files.
- Keep emitted prompts concise, scoped, and task-specific.
- Prefer `bootstrap/emit-host-prompt.sh` when the repo provides it instead of rebuilding the startup preamble ad hoc.
- When a host cannot resolve repo-local file paths directly, prefer `bootstrap/emit-host-bundle.sh` and follow `_system/HOST_BUNDLE_CONTRACT.md`.
- Keep tool-entry adapter files aligned through `_system/HOST_ADAPTER_POLICY.md` and `bootstrap/generate-host-adapters.sh` instead of hand-editing shared startup language repeatedly.
- When the task maps cleanly to one of the standard AIAST bundles, name the
  relevant bundle from `_system/READ_BUNDLES.md` instead of expanding to the full
  tiered load by default.

## Required startup preamble

Every emitted prompt should contain a compact version of this instruction:

`Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first. Treat this host prompt as orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.`

## Emission rules

- Use repo-local file paths, not paraphrased pseudo-paths.
- Do not restate full copies of `AGENTS.md`, `_system/MASTER_SYSTEM_PROMPT.md`, or `_system/PROJECT_RULES.md` unless a target tool requires a minimal excerpt.
- Prefer saying "read these files" over embedding long rule text.
- If a host needs a self-contained export instead of live path access, emit a narrow host bundle rather than copying large rule bodies into ad hoc prompts.
- If the target task is narrow, reference only the additional domain files needed for that task.
- If the task depends on current framework, package, platform, installer, or API
  behavior, include `_system/VERSION_SENSITIVE_RESEARCH_PROTOCOL.md` in the read
  set and label any current-state assumptions explicitly.
- If a host adds reporting format or delivery steps, label that as host-level context rather than repo-local truth.
- Remember that prompt emission surfaces sit below the repo-local core and any tool overlay in the precedence stack.

## Safe structure

1. Host-safe startup preamble.
2. Task objective and scope.
3. Required repo-local files to read beyond the startup preamble.
4. Constraints, validation, and reporting requirements.
5. Deliverables.

## Forbidden prompt emission patterns

- Declaring the host prompt to be the only source of truth.
- Overwriting repo-local runtime facts with generic assumptions.
- Duplicating long rule bodies from `_system/` into every emitted prompt.
- Omitting the repo/runtime boundary when the task touches runtime code.

## Terminology alignment

- `repo-local truth` means runtime/config/docs plus the authoritative AIAST core docs.
- `host-level orchestration context` means external task framing emitted outside the repo.
- `tool overlay` means a tool-specific adapter layered on top of the shared repo-local core.
- `runtime system boundary` means runtime code must remain independent from `_system/`.
- `workspace_authority` (workspace authority) means downstream repos trust the working-directory copy as authority while parent/global files stay redirect-only.

## Related files

- `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`
- `_system/REPO_OPERATING_PROFILE.md`
- `_system/HOST_BUNDLE_CONTRACT.md`
- `_system/READ_BUNDLES.md`
- `_system/VERSION_SENSITIVE_RESEARCH_PROTOCOL.md`
- `_system/PROMPTS_INDEX.md`
- `_system/HOST_ADAPTER_POLICY.md`
- `_system/prompt-templates/`
- `_system/prompt-packs/`
- `_system/host-adapter-manifest.json`
- `bootstrap/generate-host-adapters.sh`
- `bootstrap/check-host-adapter-alignment.sh`
- `bootstrap/emit-host-prompt.sh`
- `bootstrap/check-host-ingestion.sh`
- `bootstrap/emit-host-bundle.sh`
- `bootstrap/check-host-bundle.sh`
