# Standards Conflict Resolution

When two or more standards pull in different directions, use this matrix to decide.

## Priority order

When standards conflict, resolve in this order:

1. **Safety and correctness** — never sacrifice data integrity, security, or authorization for any other concern.
2. **Accessibility** — user access is a hard requirement, not a polish item. WCAG AA is the floor.
3. **Performance** — respect budgets in `PERFORMANCE_BUDGET.md`, but only after safety and accessibility are met.
4. **Maintainability** — prefer clear, understandable code over clever optimization unless measurement justifies it.
5. **Design polish** — visual refinement comes after the above are satisfied.

## Common conflicts and resolutions

### Performance vs. accessibility

- **Resolution**: Accessibility wins. A fast page that cannot be used is not fast — it is broken.
- **Example**: Do not remove ARIA attributes or semantic structure to reduce DOM size. Use virtualization instead.
- **Exception**: If accessibility instrumentation causes a measured, user-visible performance regression (not a synthetic benchmark), find an alternative implementation, not a removal.

### Performance vs. maintainability

- **Resolution**: Maintainability wins unless profiling shows a measured bottleneck on a hot path.
- **Example**: Do not hand-optimize a loop that runs once per page load. Do optimize a rendering loop that fires 60 times per second.
- **Rule**: Profile first. If no measurement exists, the simpler code is correct.

### Security vs. usability

- **Resolution**: Security wins at system boundaries. Inside trusted internal code, prefer usability.
- **Example**: Always validate and sanitize user input at the API boundary. Do not add redundant validation inside private helper functions.
- **Exception**: If a security measure makes a critical workflow unusable (login takes 30 seconds), find a less intrusive mechanism, not a bypass.

### Code simplicity vs. completeness

- **Resolution**: Completeness wins for error states, empty states, and edge cases in user-facing surfaces. Simplicity wins for internal plumbing.
- **Example**: A user-facing form must handle validation errors, loading states, and success feedback. An internal data transform function does not need defensive checks for types guaranteed by the caller.

### Consistency vs. correctness

- **Resolution**: Correctness wins. Do not propagate a wrong pattern just because the codebase already uses it.
- **Example**: If existing code uses `<div onClick>` instead of `<button>`, new code should use `<button>`. Fix the existing code when the scope allows.

### Bundle size vs. feature completeness

- **Resolution**: Follow the performance budget. If the budget allows it, ship the feature. If it exceeds the budget, code-split or lazy-load.
- **Example**: A charting library that adds 80KB gzipped to the main bundle should be lazy-loaded on the route that uses it, not removed.

### Test coverage vs. delivery speed

- **Resolution**: Tests are required for behavior changes, bug fixes, and contract changes. Tests are optional for pure refactors that do not change behavior.
- **Example**: A renamed variable does not need a new test. A changed API response shape does.

## How to document a trade-off

When a decision requires bending a standard, record it:

1. **In the code**: Add a comment explaining why the standard was bent and what would restore it.
2. **In `_system/context/DECISIONS.md`**: Record the decision, the conflicting standards, and the rationale.
3. **In `RISK_REGISTER.md`**: If the trade-off introduces ongoing risk, track it with a revisit trigger.

## Escalation

If a conflict cannot be resolved by this matrix:

1. Check `_system/context/ARCHITECTURAL_INVARIANTS.md` for prior rulings.
2. Check `_system/context/DECISIONS.md` for precedent.
3. If no precedent exists, document both options and their trade-offs in `_system/context/OPEN_QUESTIONS.md` with a recommendation.
4. Default to the safer, more reversible option until resolved.
