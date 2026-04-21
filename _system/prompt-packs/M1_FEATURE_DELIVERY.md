# M1 Feature Delivery Prompt Pack

## M1.0 Planning

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Read the canonical docs and plan the requested feature.

Deliver:
1. Scope breakdown
2. Files to touch
3. Data/API/UI impact
4. Active role split and write ownership if delegation is useful
5. Validation plan
6. Risks and rollback notes
```

## M1.1 Implementation

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Implement only the planned feature slice.

Constraints:
- minimal diffs
- one active writer unless disjoint write scopes were assigned explicitly
- no unrelated refactors
- add or update tests
- update docs if contracts or behavior changed
```

## M1.2 Handoff

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Update TODO.md, FIXME.md, WHERE_LEFT_OFF.md, and CHANGELOG.md as needed.

Report:
1. What changed
2. Validation run
3. Remaining blockers
4. Next best step
```
