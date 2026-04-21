# M16 Platform Product Expansion

## M16.0 Platform expansion planning

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md,
_system/REPO_OPERATING_PROFILE.md, _system/LOAD_ORDER.md,
_system/PROJECT_PROFILE.md, PRODUCT_BRIEF.md, PLAN.md, and TODO.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with
repo-local files, follow the repo-local files and report the conflict.

Plan the strongest next bounded slice to expand the product into a coherent
multi-surface platform (website + mobile/cellular app + shared backend where needed).

Deliver:
1. platform baseline map (current web/mobile/backend status)
2. instruction and precedence findings for this repo
3. selected one-slice expansion milestone
4. file-level implementation plan
5. compatibility + rollback strategy
6. validation commands and release-risk checks
7. exact next execution prompt
```

## M16.1 Platform expansion execution

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md,
_system/REPO_OPERATING_PROFILE.md, _system/LOAD_ORDER.md,
_system/PROJECT_PROFILE.md, PRODUCT_BRIEF.md, PLAN.md, and TODO.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with
repo-local files, follow the repo-local files and report the conflict.

Execute the selected platform expansion slice.

Rules:
- one coherent slice only
- preserve existing runtime behavior unless explicitly approved
- keep contracts backward-compatible where possible
- include security, performance, and accessibility checks in changed surfaces
- add tests for changed behavior and include negative-path coverage where relevant
- update runbook/release docs if operator behavior changed
- record evidence-based validation outcomes only
- if the product now launches on a new surface, follow
  `_system/AGENT_INSTALLER_AND_HOST_VALIDATION_PROTOCOL.md`
  and `_system/CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md`

Return exactly:
1. selected work item
2. files touched
3. changes made
4. validation run
5. result
6. compatibility / rollback notes
7. remaining gaps
8. exact next prompt
```

## M16.2 Platform quality hardening

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md,
_system/REPO_OPERATING_PROFILE.md, _system/LOAD_ORDER.md,
_system/PROJECT_PROFILE.md, PLAN.md, TEST_STRATEGY.md, and RISK_REGISTER.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with
repo-local files, follow the repo-local files and report the conflict.

Harden the currently changed platform surfaces for world-class delivery quality
without widening product scope.

Audit and improve:
- auth/session consistency across web and mobile
- API contract stability and versioning
- error handling, degraded states, and telemetry
- performance hotspots on each surface
- accessibility and responsive behavior
- rollback and kill-switch readiness

Return exactly:
1. highest-risk findings
2. severity ranking
3. smallest safe hardening fix set
4. files/surfaces involved
5. validation and confidence evidence
6. remaining risks
7. exact next implementation prompt
```
