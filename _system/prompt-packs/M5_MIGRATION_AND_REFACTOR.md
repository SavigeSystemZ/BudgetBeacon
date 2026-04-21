# M5 Migration And Refactor Prompt Pack

## M5.0 Refactor plan

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Plan the refactor or migration.

Deliver:
1. what changes structurally
2. what must stay behaviorally identical
3. phased implementation order
4. rollback path
5. validation plan
```

## M5.1 Refactor execution

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Apply the refactor in the smallest safe increments.

Constraints:
- separate structural cleanup from behavior changes where possible
- preserve continuity files and documentation
```
