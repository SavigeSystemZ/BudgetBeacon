# Optimization Prompt Template

Use this template when profiling, measuring, or optimizing performance for the project.

## Host-safe preamble

- Load `AGENTS.md`, `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`, `_system/REPO_OPERATING_PROFILE.md`, and `_system/LOAD_ORDER.md` first.
- Treat the host prompt as orchestration context only; repo-local files remain authoritative.

## Template

```
Context:
- Project: [app name from PROJECT_PROFILE.md]
- Stack: [relevant stack details]
- Target: [what is being optimized — page load, API response, build time, bundle size, query performance]
- Current measurement: [baseline metric if known]
- Budget: [target metric from PERFORMANCE_BUDGET.md]

Task:
[Describe the optimization goal]

Constraints:
- Must not regress functionality or break existing tests.
- Must not introduce new dependencies unless justified per DEPENDENCY_GOVERNANCE.md.
- Must provide before/after measurements.
- Must be reversible or clearly documented.

Approach:
1. Profile the current state and identify the bottleneck.
2. Apply the smallest change that addresses the bottleneck.
3. Measure the result.
4. Document the change, measurement, and any trade-offs.

Output:
- Before/after measurements.
- Files changed.
- Trade-offs or risks introduced.
- Remaining optimization opportunities.
```
