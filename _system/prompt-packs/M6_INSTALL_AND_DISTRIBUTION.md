# M6 Install And Distribution Prompt Pack

## M6.0 Ops plan

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Also load _system/CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md and _system/AGENT_INSTALLER_AND_HOST_VALIDATION_PROTOCOL.md when changing installers, distribution/, packaging, or host bindings.
Load _system/SUB_AGENT_HOST_DELEGATION.md when the plan involves coordinating multiple host tools or terminals for delivery work.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Plan install, launch, packaging, or distribution work.

Deliver:
1. impacted scripts and runtime paths
2. required verification commands
3. user-facing risks
4. rollback and recovery notes
```

## M6.1 Ops implementation

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Implement the smallest correct operational change.

Constraints:
- verify the real runtime path
- update docs for install or launch behavior
- do not claim packaging success without artifacts or explicit command results
```
