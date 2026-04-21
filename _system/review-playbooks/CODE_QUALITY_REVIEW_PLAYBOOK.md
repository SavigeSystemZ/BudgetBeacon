# Code Quality Review Playbook

## Review inputs

- changed files
- `_system/CODING_STANDARDS.md`
- `_system/PROJECT_RULES.md`
- `_system/PROJECT_PROFILE.md` (stack and conventions sections)

## Review for

1. **Naming clarity**: Are functions, variables, types, and files named to reveal intent? No abbreviations, no generic names?
2. **Function design**: Single responsibility? Reasonable length? Limited parameters? No boolean flag branching?
3. **Error handling**: Are errors handled at the right boundary? Typed errors with context? No silent swallowing?
4. **Resource management**: Are connections, handles, timers, and subscriptions cleaned up? No unbounded collections?
5. **Type safety**: Strong types at boundaries? No unnecessary `any` or unchecked casts?
6. **Data validation**: Input validated at boundaries? Schema validation for complex shapes? Sanitized before rendering?
7. **Async correctness**: All async work properly awaited? Timeouts set? Cancellation handled? No race conditions?
8. **Testing**: New behavior tested? Modified behavior has updated tests? Tests are deterministic and meaningful?
9. **Complexity**: No premature abstraction? No over-engineering? Simplest correct solution?
10. **Anti-patterns**: No god objects, deep nesting, magic constants, copy-paste duplication, or commented-out code?

## Must-fix findings

- Silent error swallowing.
- Resource leaks (unclosed connections, uncleared timers, orphaned subscriptions).
- Missing input validation at system boundaries.
- Type safety bypassed without justification.
- Untested behavior changes.
- Security-relevant anti-patterns (SQL injection, XSS, command injection vectors).

## Output format

```
## Code Quality Review

### Must-fix
- [ ] finding (file:line) — impact

### Should-fix
- [ ] finding (file:line) — rationale

### Quality signals
- naming: clear/needs work
- error handling: robust/incomplete
- resource management: clean/has leaks
- type safety: strong/has gaps
- test coverage: adequate/insufficient
- complexity: appropriate/over-engineered
```
