# Workspace Authority And Containment Protocol

This protocol defines which AIAST surfaces are authoritative in each working mode and where writes are permitted.

**See also:** `AGENT_CONTEXT_CONTAINMENT_CONTRACT.md` — defines which agent contexts must stay repo-local and prohibits parent-directory leakage.

## Authority model

- `~/.MyAppZ/` is the top-level authority boundary for this installed operating system.
- Agents running inside `~/.MyAppZ/` must not write outside `~/.MyAppZ/` unless the operator explicitly requested, approved, and authorized that exact out-of-bound write.
- **Working Location Rule:** Whatever is being worked on MUST be worked on from within the parent working directory folder (in the local repository folder), and NEVER from outside of it.
- For `~/.MyAppZ/<ProjectName>/`, the authoritative system is the project-local copy:
  - `AGENTS.md`
  - `_system/`
  - top-level adapters
  - tool overlays inside the repo
- MetaSystems too, they are logically stored separate within that local repository, not centralized.
- `~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/` is the canonical scaffold source, not the active authority for sibling project repos. Agents should never come back and use the metasystem template from here to work on an application.
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
- Project-scoped rule: an agent assigned to `~/.MyAppZ/<ProjectName>/` must not write to sibling project directories unless explicitly requested, approved, and authorized by the operator.
- Template-source rule: writes to `~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/` are allowed only when the active agent is running from that directory (or when the operator explicitly authorizes cross-directory writes).
- Additional writable surfaces by policy:
  - approved redirect shim locations
  - orphan snapshot branches for continuity
- Any other out-of-repo write requires explicit user confirmation.

## Enforcement

- `bootstrap/check-working-directory-alignment.sh`
- `bootstrap/check-project-target-consistency.sh`
- `bootstrap/check-global-shim-alignment.sh`
- `bootstrap/system-doctor.sh` (authority/scope checks)
- `bootstrap/agent-isolation.sh` (repo-local temp/cache/state isolation for parallel agent sessions)

## Containment preflight (before write-heavy work)

Run this checklist in order for risky, cross-repo, or high-impact sessions:

1. Confirm working mode (template maintainer vs downstream project).
2. Verify requested write targets are inside allowed boundaries.
3. Validate no conflicting active writer is present for overlapping scope.
4. Run alignment checks:
   - `bootstrap/check-working-directory-alignment.sh`
   - `bootstrap/check-project-target-consistency.sh`
5. If any check fails, halt writes and request explicit operator confirmation.

## Operation risk tiers

- **Safe:** read-only analysis, docs-only updates inside current repo scope.
- **Guarded:** contract, bootstrap, or workflow changes that can affect install/runtime behavior; require validation evidence before handoff.
- **Forbidden by default:** silent cross-project writes, authority bypasses, destructive operations without explicit operator instruction.
