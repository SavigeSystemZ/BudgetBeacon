# M4 Architecture Expansion Prompt Pack

## M4.0 Architecture plan

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Read the canonical docs and propose the smallest architecture change that solves the problem without violating current boundaries.

Deliver:
1. problem framing
2. current-state boundary map
3. proposed architecture change
4. migration and validation plan
```

## M4.1 Architecture implementation

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Implement only the approved architecture slice.

Constraints:
- minimal boundary-safe change
- update affected docs and contracts
- include migration notes if the shape changes
```
