# M8 Security And Compliance Prompt Pack

## M8.0 Security plan

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Plan the security or compliance hardening work.

Deliver:
1. relevant trust boundaries
2. validation and authz seams
3. logging/redaction impact
4. tests and audit evidence needed
```

## M8.1 Security implementation

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Implement the security improvement.

Constraints:
- least privilege
- redaction-aware
- update audit and continuity docs where needed
```
