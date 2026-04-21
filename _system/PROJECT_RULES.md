# Project Rules

## 1. Boundary rules

1. Runtime code must remain independent from `_system/`.
2. Agent-only prompts, skills, rules, and MCP policy live in `_system/` or tool-specific directories such as `.cursor/`.
3. Do not hide project-critical rules inside chat. Persist them in repo files.
4. Keep runtime, system, and backup/archive layers logically separate.

## 1a. Instruction-layer rules

- Use `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md` whenever repo-local and host-level instructions overlap.
- Repo-local runtime and product facts override generic host assumptions.
- Host systems may add orchestration context, but they must not silently overwrite repo-local truth.
- Prompt templates and prompt packs must follow `_system/PROMPT_EMISSION_CONTRACT.md`.
- Golden examples may guide structure and quality level, but they must never be copied forward as donor-app truth.

## 2. Change discipline

5. Prefer the smallest correct diff over broad rewrites.
6. If a refactor is required before a behavior change, split the work logically.
7. Avoid unrelated refactors while solving a targeted problem.
8. Do not silently rewrite another agent's unresolved work.
9. Record discovered follow-up work in `TODO.md` or `FIXME.md` before handoff.

## 3. Architecture and code quality

10. Preserve module boundaries unless there is a deliberate, documented change.
11. Prefer typed interfaces, explicit errors, and predictable data flow.
12. Keep functions and modules focused; avoid clever abstraction unless duplication clearly justifies it.
13. Use actionable logs and explicit degraded states instead of silent failure.

## 4. Validation discipline

14. Run the narrowest relevant checks first, then broaden validation according to risk.
15. Never claim validation without real command evidence.
16. If install, launch, packaging, or deployment behavior changed, run runtime verification, not just lint/tests.
17. If contracts, schema, or API behavior changed, update tests and docs in the same pass.

## 5. Documentation and continuity

18. `WHERE_LEFT_OFF.md` is the primary handoff anchor.
19. `TODO.md` must capture remaining work and newly discovered work.
20. `FIXME.md` must capture unresolved bugs, debt, and blockers.
21. `PRODUCT_BRIEF.md`, `PLAN.md`, `TEST_STRATEGY.md`, `DESIGN_NOTES.md`, and `ARCHITECTURE_NOTES.md` should be updated when the work changes product direction, execution, confidence, design, or structure.
22. `RISK_REGISTER.md` should track active delivery, security, quality, or release risk.
23. `RELEASE_NOTES.md` and `CHANGELOG.md` should track outward-facing changes and release posture.

## 6. Security and operational rules

24. Never commit secrets, raw credentials, or sensitive exports.
25. Validate inputs at boundaries and preserve authorization seams.
26. Redact sensitive material from logs, prompts, reports, and generated artifacts.
27. Default to least privilege for MCP, tooling, and operational actions.

## 7. Performance and resource efficiency

28. Do not ship unbounded data fetches, unindexed queries, or uncapped collection growth.
29. Clean up resources (connections, listeners, timers, subscriptions) when their scope ends.
30. Set timeouts on all external calls. Never wait indefinitely.
31. Use lazy loading and code splitting for non-critical features.
32. Profile before optimizing. Measure, do not guess.
33. Respect performance budgets defined in `_system/PERFORMANCE_BUDGET.md` when they exist.

## 8. Accessibility

34. Use semantic HTML elements for their intended purpose. A button is a `<button>`.
35. Every interactive element must be keyboard accessible.
36. All form inputs must have associated labels.
37. Meet WCAG 2.2 AA contrast ratios for text and interactive elements.
38. Respect `prefers-reduced-motion` and `prefers-color-scheme`.
39. Test with keyboard navigation for all interactive flows.

## 9. Dependency management

40. Every new dependency must justify its inclusion. Prefer standard library solutions.
41. Pin exact versions. Commit lockfiles.
42. Run security audits in CI. Fail on critical vulnerabilities.
43. Review licenses before adding dependencies.
44. Remove unused dependencies promptly.

## 10. Collaboration rules

45. Assume multiple agents may take turns.
46. Single active writer only.
47. Every meaningful handoff must include files changed, validation run, blockers, and next step.
48. Review mode prioritizes bugs, regressions, and missing validation over style.
