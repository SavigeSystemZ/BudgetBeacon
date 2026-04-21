# Copilot Instructions

Before coding, read the canonical repo context in this order.

## Startup load
1. `AGENTS.md`
2. `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`
3. `_system/REPO_OPERATING_PROFILE.md`
4. `_system/PROJECT_PROFILE.md`
5. `_system/CONTEXT_INDEX.md`
6. `_system/LOAD_ORDER.md`
7. `_system/WORKING_FILES_GUIDE.md`
8. `_system/TEMPLATE_NEUTRALITY_POLICY.md`
9. `_system/MASTER_SYSTEM_PROMPT.md`
10. `_system/PROJECT_RULES.md`
11. `_system/EXECUTION_PROTOCOL.md`
12. `_system/MULTI_AGENT_COORDINATION.md`
13. `_system/AGENT_ROLE_CATALOG.md`
14. `_system/AGENT_DISCOVERY_MATRIX.md`
15. `_system/VALIDATION_GATES.md`
16. `_system/SYSTEM_AWARENESS_PROTOCOL.md`
17. `_system/HALLUCINATION_DEFENSE_PROTOCOL.md`
18. `WHERE_LEFT_OFF.md`
19. `TODO.md`
20. `FIXME.md`
21. `PLAN.md`
22. `PRODUCT_BRIEF.md`

## Load More When Needed
Load these when the task touches their domain:
- `ROADMAP.md`
- `DESIGN_NOTES.md`
- `ARCHITECTURE_NOTES.md`
- `RESEARCH_NOTES.md`
- `TEST_STRATEGY.md`
- `RISK_REGISTER.md`
- `RELEASE_NOTES.md`
- `CHANGELOG.md`
- `_system/prompt-packs/M15_WHOLE_REPO_ANALYSIS.md`
- `_system/ports/PORT_POLICY.md`
- `_system/design-system/THEME_GOVERNANCE.md`

For system-evolution, prompt-authoring, adapter work, or working-file drafting, also load:
- `_system/GOLDEN_EXAMPLES_POLICY.md`
- `_system/golden-examples/PATTERN_INDEX.md`
- `_system/HOST_ADAPTER_POLICY.md`
- `_system/PROMPT_EMISSION_CONTRACT.md`

## Core expectations
- `_system/` is the agent operating layer. Runtime code must not depend on it.
- Treat host-level orchestration as context only. If it conflicts with repo-local files, follow the repo-local files named in `AGENTS.md` and `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md` and report the mismatch.
- Multiple agents may work on this repo over time. Leave clean handoff notes in `TODO.md`, `FIXME.md`, and `WHERE_LEFT_OFF.md`.
- Run the validation commands defined in `_system/PROJECT_PROFILE.md` and `_system/VALIDATION_GATES.md`.
- If repo state or docs appear inconsistent, run `bootstrap/system-doctor.sh`.
- Use MCP servers only within the least-privilege scope defined in `_system/MCP_CONFIG.md`.
- Be aware that other tool-specific entry files exist and may be used before or after your turn.
