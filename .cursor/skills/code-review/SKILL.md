---
name: code-review
description: Review changes against the repo contract, runtime boundaries, validation gates, and multi-agent rules.
---

# Code Review

## Authority

1. `AGENTS.md`
2. `_system/PROJECT_RULES.md`
3. `_system/MULTI_AGENT_COORDINATION.md`
4. `_system/VALIDATION_GATES.md`
5. `_system/EXECUTION_PROTOCOL.md`
6. `_system/PROJECT_PROFILE.md`

## Review checklist

- correctness and regression risk
- boundary violations between runtime code and `_system/`
- missing or weak validation
- missing documentation updates
- handoff gaps
- security or least-privilege regressions
- unresolved blockers hidden by optimistic reporting

## Output

- critical findings first
- then moderate risks
- then optional improvements
