# M2 Debug And Stabilize Prompt Pack

## M2.0 Reproduce

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Reproduce the failure before making changes.

Deliver:
1. Exact repro steps
2. Expected vs actual behavior
3. Smallest failing surface
```

## M2.1 Fix

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Apply the smallest correct fix.

Constraints:
- separate refactor from behavior change if both are needed
- add tests to prevent recurrence
- keep logs and error handling actionable
```

## M2.2 Verify

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Run the full relevant validation ladder after the fix.

Deliver:
1. Commands run
2. Results
3. Remaining risk
4. Rollback note
```
