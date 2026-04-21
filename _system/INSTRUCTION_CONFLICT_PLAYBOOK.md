# Instruction Conflict Playbook

Use this playbook when multiple instruction layers overlap, duplicate each other, or pull in different directions.

## Typical symptoms

- Two adapter files claim different startup documents.
- A host prompt restates repo rules and changes their meaning.
- Validation expectations differ between entrypoints.
- A tool overlay says something about file ownership or runtime boundaries that the core docs do not allow.
- Prompt packs duplicate long rule bodies and drift from the repo-local contract.

## First response

1. Run `bootstrap/detect-instruction-conflicts.sh <repo> --strict`.
2. Identify whether the problem is factual truth, repo-local policy, tool overlay behavior, or host-level orchestration.
3. Resolve it using `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`.

## Resolution order

- Factual runtime or product truth: edit the actual repo-local source of truth.
- Shared repo operating rules: edit `AGENTS.md` and the authoritative `_system/` contract files.
- Tool-specific wording drift: edit the tool adapter or overlay file.
- Prompt emission drift: edit `_system/PROMPT_EMISSION_CONTRACT.md`, `_system/prompt-templates/`, or `_system/prompt-packs/`.
- Host-level orchestration mismatch: change the host prompt or add an explicit conflict note instead of mutating repo-local truth to match the host.

## Which file to touch

- `AGENTS.md`: shared top-level repo contract.
- `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`: precedence and conflict rules.
- `_system/REPO_OPERATING_PROFILE.md`: machine-friendly ingestion summary for hosts.
- `_system/AGENT_DISCOVERY_MATRIX.md`: adapter discovery and coexistence rules.
- Tool adapter files: tool-specific emphasis only.
- `_system/PROMPT_EMISSION_CONTRACT.md`: host-safe prompt generation behavior.

## Do not do this

- Do not let a host system silently replace repo-local facts.
- Do not copy large rule bodies into every adapter or prompt pack.
- Do not treat prompt packs as primary authority.
- Do not change runtime code to satisfy an instruction-layer contradiction.

## Recordkeeping

When a conflict cannot be eliminated immediately:

1. Record the conflict and chosen fallback in `WHERE_LEFT_OFF.md`.
2. Add follow-up cleanup in `TODO.md` or `_system/context/OPEN_QUESTIONS.md`.
3. Keep the repo-local source of truth explicit so the next tool does not have to guess.
