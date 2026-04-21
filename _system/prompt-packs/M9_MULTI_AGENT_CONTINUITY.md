# M9 Multi-Agent Continuity Prompt Pack

## M9.0 Continuity plan

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Load _system/SUB_AGENT_HOST_DELEGATION.md when the plan includes parallel host CLI or IDE auxiliary sessions (optional; not auto-spawned).
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Plan the changes needed to improve handoff quality, context durability, or tool interoperability.

Deliver:
1. current continuity or delegation gaps
2. role-model or ownership changes needed
3. files to update
4. validation and adoption plan
```

## M9.1 Continuity implementation

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Load _system/SUB_AGENT_HOST_DELEGATION.md if you are defining or tightening parallel host auxiliary workflows.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Implement the continuity improvements.

Constraints:
- shared core remains canonical
- adapters remain aligned
- `_system/AGENT_ROLE_CATALOG.md` stays aligned with prompt packs and role overlays
- update discovery matrix and handoff files if the workflow changes
```
