# Instruction Precedence Contract

This contract defines how AIAST behaves when repo-local instructions, tool adapters, prompt packs, and host-level orchestration layers all exist at the same time.

The goal is not to pretend collisions never happen. The goal is to minimize them, detect them, and resolve them in a repeatable way.

**Related map:** `_system/SYSTEM_ORCHESTRATION_GUIDE.md` — how this contract fits with discovery, load order, validation, and conflict playbooks (does not change precedence rules below).

## Roles

- Repo-local runtime and product files hold factual truth about the app.
- Repo-local AIAST core files hold the authoritative repo operating contract.
- Tool adapters translate the shared repo contract into tool-specific entrypoints.
- Adapter placeholders are compatibility entrypoints and cannot redefine shared policy.
- Prompt packs and prompt templates are reusable emission surfaces, not primary authority.
- Host-level systems may add task framing, sequencing, and operator intent, but they are not allowed to silently replace repo-local truth.
- Workspace/global redirect surfaces are compatibility shims only and cannot become alternate authorities.

## Authoritative repo-local files

Treat these as the authoritative repo-local instruction layer:

1. `AGENTS.md`
2. `_system/PROJECT_PROFILE.md`
3. `_system/PROJECT_DOMAIN_MANIFEST.json` (declared product domain and off-domain instruction guards)
4. `_system/INSTRUCTION_DOMAIN_ALIGNMENT_PROTOCOL.md` (wrong-app / wrong-vertical pasted prompts)
5. `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`
6. `_system/REPO_OPERATING_PROFILE.md`
7. `_system/LOAD_ORDER.md`
8. `_system/MASTER_SYSTEM_PROMPT.md`
9. `_system/PROJECT_RULES.md`
10. `_system/AGENT_ROLE_CATALOG.md`
11. `_system/AGENT_DISCOVERY_MATRIX.md`

When the question is factual rather than instructional, the highest authority is the actual repo runtime/configuration surface itself: source code, migrations, schemas, tests, package manifests, deployment config, and operator docs.

## Consistency surfaces

These surfaces are not a second authority layer, but they must stay semantically
aligned with the core contract:

- `_system/LOAD_ORDER.md`
- `_system/PROJECT_DOMAIN_MANIFEST.json`
- `_system/INSTRUCTION_DOMAIN_ALIGNMENT_PROTOCOL.md`
- `_system/REPO_OPERATING_PROFILE.md`
- `_system/repo-operating-profile.json`
- `_system/PROMPT_EMISSION_CONTRACT.md`
- `_system/HOST_BUNDLE_CONTRACT.md`
- `_system/READ_BUNDLES.md`
- `_system/TEMPLATE_CHANGE_IMPACT_POLICY.md`
- `_system/SELF_HEALING_BOUNDARY.md`
- `_system/VERSION_SENSITIVE_RESEARCH_PROTOCOL.md`

The machine-readable companion `_system/instruction-precedence.json` carries the
same precedence structure plus the current template release marker, so patch
releases must update the prose contract and the JSON manifest together even when
the precedence order itself does not change.

A mid-session **resume checkpoint** written under `_system/checkpoints/` via
`bootstrap/write-checkpoint.sh` is a continuity surface, not an authority
surface: it reports what the previous agent was doing and what should happen
next, but it does not override any authoritative repo-local file. When a
checkpoint's `next_actions` appear to conflict with the current state of the
authoritative files, trust the authoritative files and write a fresh
checkpoint that reflects reality before continuing. See
`_system/CHECKPOINT_PROTOCOL.md` for the full cross-agent checkpoint contract.

## Precedence order

Resolve instruction layers in this order:

1. Repo-local runtime and product truth.
2. Repo-local AIAST core contract.
3. Tool-specific overlays such as `CODEX.md`, `CLAUDE.md`, `GEMINI.md`, `WINDSURF.md`, `.cursorrules`, `.windsurfrules`, `.cursor/`, and `.github/copilot-instructions.md`.
   Compatibility placeholders such as `CURSOR.md`, `COPILOT.md`, `AIDER.md`, and `AGENT_ZERO.md` are overlays in this same layer.
4. Repo-local prompt emission surfaces such as `_system/PROMPT_EMISSION_CONTRACT.md`, `_system/prompt-templates/`, and `_system/prompt-packs/`.
5. Host-level orchestration context emitted outside the repo.

## Conflict rules

- If host instructions conflict with repo-local runtime or product facts, repo-local facts win.
- If a tool adapter conflicts with `AGENTS.md` or the AIAST core docs, the AIAST core docs win.
- If a prompt pack conflicts with the repo-local core docs, the repo-local core docs win.
- If two repo-local docs conflict, prefer the more specific factual source:
  actual runtime/config files over profile summaries, and profile summaries over generic templates.
- Host systems must not silently overwrite repo-local truth. They should surface the mismatch to the operator or tell the coding agent to record it in repo artifacts.

## Adapter and host expectations

- Every tool adapter must point back to `AGENTS.md`, this contract, and the repo operating profile.
- Host-safe emitted prompts must distinguish host-level orchestration context from repo-local truth.
- Host-safe emitted prompts must reference canonical repo files by path instead of copying long rule bodies.
- Host systems may add sequencing, delivery requirements, and reporting format, but they must not redefine repo ownership, runtime boundaries, or validation outcomes.

## Terminology

- `repo-local truth`: facts stored in repo files, especially runtime/config/code surfaces and authoritative AIAST core docs.
- `host-level orchestration context`: instructions emitted outside the repo that describe operator intent, sequencing, or reporting expectations.
- `tool overlay`: a tool-specific adapter or rules layer that sits on top of the repo-local core.
- `runtime/system boundary`: the rule that runtime code must remain independent from `_system/`.
- `workspace authority`: for downstream repos, authority is the working-directory copy, not parent/global shims.

## Resolution workflow

1. Load `AGENTS.md`, this contract, `_system/REPO_OPERATING_PROFILE.md`, and `_system/LOAD_ORDER.md`.
2. Identify whether the conflict is about facts, rules, tool behavior, or host context.
3. Resolve it with the precedence order above.
4. Keep the consistency surfaces aligned with the core contract when authority or
   recovery behavior changes.
5. If the host/tool layer cannot be adjusted, record the collision and the
   chosen fallback in repo handoff artifacts.
6. Run `bootstrap/detect-instruction-conflicts.sh <repo> --strict` when the
   overlap is structural rather than task-local.
