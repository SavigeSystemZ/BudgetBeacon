---
name: environment-report
description: Emit an environment and authority report before write-heavy work or cross-repo tasks.
---

# Load Context

## Steps
Run `bash bootstrap/check-working-directory-alignment.sh .` and `bash bootstrap/check-project-target-consistency.sh .` before environment reporting.

1. Read `AGENTS.md`.
2. Read `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`.
3. Read `_system/REPO_OPERATING_PROFILE.md`.
4. Read `_system/PROJECT_PROFILE.md`.
5. Read `_system/CONTEXT_INDEX.md`.
6. Read `_system/LOAD_ORDER.md`.
7. Read `_system/WORKING_FILES_GUIDE.md`.
8. Read `_system/TEMPLATE_NEUTRALITY_POLICY.md`.
9. Read `_system/MASTER_SYSTEM_PROMPT.md`.
10. Read `_system/PROJECT_RULES.md`.
11. Read `_system/EXECUTION_PROTOCOL.md`.
12. Read `_system/MULTI_AGENT_COORDINATION.md`.
13. Read `_system/AGENT_ROLE_CATALOG.md`.
14. Read `_system/AGENT_DISCOVERY_MATRIX.md`.
15. Read `_system/VALIDATION_GATES.md`.
16. Read `_system/SYSTEM_AWARENESS_PROTOCOL.md`.
17. Read `_system/HALLUCINATION_DEFENSE_PROTOCOL.md`.
18. Read `WHERE_LEFT_OFF.md`.
19. Read `TODO.md`.
20. Read `FIXME.md`.
21. Read `PLAN.md`.
22. Read `PRODUCT_BRIEF.md`.
23. If the task touches design, architecture, research, testing, risk, or release, also read `ROADMAP.md`, `DESIGN_NOTES.md`, `ARCHITECTURE_NOTES.md`, `RESEARCH_NOTES.md`, `TEST_STRATEGY.md`, `RISK_REGISTER.md`, `RELEASE_NOTES.md`, and `CHANGELOG.md` as needed.
24. If the task is greenfield, system-evolution, prompt-authoring, adapter work, or working-file authoring, also read `_system/GOLDEN_EXAMPLES_POLICY.md`, `_system/golden-examples/PATTERN_INDEX.md`, `_system/HOST_ADAPTER_POLICY.md`, and `_system/PROMPT_EMISSION_CONTRACT.md`.

## Output
- report repo identity, authority mode, and target consistency
- report branch, remote, and orphan snapshot lane state
- call out mismatches that require confirmation before writing
