# Workspace Authority And Containment Protocol

This protocol defines which AIAST surfaces are authoritative in each working mode and where writes are permitted.

## Authority model

- For `~/.MyAppZ/<ProjectName>/`, the authoritative system is the project-local copy:
  - `AGENTS.md`
  - `_system/`
  - top-level adapters
  - tool overlays inside the repo
- `~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/` is the canonical scaffold source, not the active authority for sibling project repos.
- Parent/global surfaces are redirect shims only and cannot become alternate authorities.

## Working modes

1. **Template maintainer mode**
   - Working root is the source template repo.
   - Template/system/factory/meta evolution writes are allowed.
2. **Downstream project mode**
   - Working root is a specific app repo.
   - Only that repo is writable by default.
   - Template and sibling repos are read-only unless explicitly approved.
3. **Out-of-bound mode**
   - Working root is outside `~/.MyAppZ`.
   - AIAST contracts are advisory until operator confirmation maps them to the active repo.

## Containment rules

- No silent cross-project writes.
- No silent template writes during project-agent work.
- No global policy duplication in redirect shims.
- If working directory identity and requested target conflict, halt write operations and request confirmation.

## Write boundaries

- Default writable surface: active target repo only.
- Additional writable surfaces by policy:
  - approved redirect shim locations
  - orphan snapshot branches for continuity
- Any other out-of-repo write requires explicit user confirmation.

## Enforcement

- `bootstrap/check-working-directory-alignment.sh`
- `bootstrap/check-project-target-consistency.sh`
- `bootstrap/check-global-shim-alignment.sh`
- `bootstrap/system-doctor.sh` (authority/scope checks)
