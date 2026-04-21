Review the current diff against:

1. `AGENTS.md`
2. `_system/PROJECT_RULES.md`
3. `_system/EXECUTION_PROTOCOL.md`
4. `_system/MULTI_AGENT_COORDINATION.md`
5. `_system/VALIDATION_GATES.md`
6. `_system/CODING_STANDARDS.md`

For each changed file, evaluate:

1. **Correctness**: Does the logic do what it claims? Are edge cases handled? Are types correct?
2. **Regressions**: Could this change break existing behavior? Are callers still compatible?
3. **Boundaries**: Does the change respect module ownership? Does runtime code stay independent of `_system/`?
4. **Tests**: Are behavior changes covered by tests? If not, is the gap justified?
5. **Security**: Any injection risks, exposed secrets, missing input validation, or overprivileged access?
6. **Readability**: Is the intent clear? Are names descriptive? Is complexity justified?

For each finding, classify severity:

- **Critical**: Will break functionality, lose data, or create a security vulnerability.
- **Moderate**: Likely to cause bugs, confuse future maintainers, or create technical debt.
- **Optional**: Style improvements, minor readability wins, or defensive additions.

Output critical issues first, then moderate risks, then optional improvements.
