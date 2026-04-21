# Failure Modes And Recovery

Use this to recover from operating-system failures without guessing.

## Common failure modes

### Context reset

- reload the canonical docs
- read `WHERE_LEFT_OFF.md`
- verify current repo state before editing

### Partial or broken bootstrap

- run `bootstrap/validate-system.sh`
- identify missing files or unresolved placeholders
- repair before using the system

### MCP failure

- follow `_system/mcp/MCP_FAILURE_FALLBACKS.md`
- continue with repo context unless the task truly depends on MCP

### Conflicting agent edits

- stop changing files blindly
- inspect the overlap
- record the conflict in `WHERE_LEFT_OFF.md`
- reduce scope or partition ownership

### Validation failure at handoff

- fix it, or
- document it explicitly before stopping

### Missing or stale project profile

- update `_system/PROJECT_PROFILE.md` before proceeding with high-risk work

### Stale working files

- compare `PLAN.md`, `TODO.md`, `WHERE_LEFT_OFF.md`, and `_system/context/CURRENT_STATUS.md`
- repair contradictions before continuing broad implementation
- update the smallest set of files needed to restore a truthful operating picture

### Hallucination or claim drift

- run `bootstrap/check-hallucination.sh`
- run `bootstrap/check-system-awareness.sh`
- if structural drift exists, run `bootstrap/heal-system.sh --source <template-root>`
- if only evidence is missing, repair the working files rather than making stronger claims

### Over-eager self-healing

- reload `_system/SELF_HEALING_BOUNDARY.md`
- switch from automatic repair to explicit review if repo-owned truth may be
  overwritten
- keep user-directed behavior unless the repo’s own rules explicitly require
  removal
