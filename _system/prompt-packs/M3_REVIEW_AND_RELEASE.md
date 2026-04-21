# M3 Review And Release Prompt Pack

## M3.0 Review

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Review the current diff against AGENTS.md, _system/PROJECT_RULES.md, _system/MULTI_AGENT_COORDINATION.md, and _system/VALIDATION_GATES.md.

Classify findings as:
- critical
- should fix
- nice to have
```

## M3.1 Release Readiness

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Assess release readiness.

Deliver:
1. validation summary
2. unresolved risk
3. install / launch / packaging concerns
4. docs that still need updates
```

## M3.2 Final Handoff

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Prepare the handoff packet for the next agent or human.

Include:
- files changed
- validations run
- blockers
- next best step
```
