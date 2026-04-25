# Scavenge And Discovery Authorization

AIAST allows read-heavy local scavenging to improve host fidelity and reduce assumptions.

## Authorized read scope

- active target repo
- `~/.MyAppZ/`
- `~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/`
- sibling repos under `~/.MyAppZ/` for donor pattern comparison
- relevant tool-global directories present on host

## Default write scope

- active target repo only

## Additional policy-approved writes

- approved global/root redirect shim locations
- approved orphan snapshot branch operations

## Forbidden writes without explicit approval

- sibling project repos
- template source during downstream project-agent work
- unrelated host directories

## Operational guardrails

- discovery should be read-first and minimal-write
- do not copy donor app truth into template doctrine
- report scavenged path classes in continuity artifacts
- if requested target and active repo disagree, halt writes and confirm
