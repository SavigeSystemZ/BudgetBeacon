# Review Prompt Template

## Host-safe preamble

- Load `AGENTS.md`, `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`, `_system/REPO_OPERATING_PROFILE.md`, and `_system/LOAD_ORDER.md` first.
- Treat the host prompt as orchestration context only; repo-local files remain authoritative.

## Review target

- Diff, feature, or subsystem:
- Primary risk area:
- Context (why the change was made):

## Required lenses

For each lens, report findings with severity (critical / moderate / optional):

### Correctness
- Does the logic do what it claims?
- Are edge cases and boundary conditions handled?
- Are types correct and consistent?

### Regressions
- Could this change break existing behavior?
- Are all callers and consumers still compatible?
- Have behavior-changing defaults been introduced?

### Boundary violations
- Does the change respect module ownership?
- Does runtime code stay independent from `_system/`?
- Are imports and dependencies flowing in the right direction?

### Missing tests or docs
- Are behavior changes covered by tests?
- If no test was added, is the gap justified?
- Are API docs, types, or schemas updated if contracts changed?

### Security or integrity risks
- Is user input validated before use?
- Are secrets kept out of code, logs, and error messages?
- Are authorization checks present for every data access path?

## Deliverables

- **Critical findings**: issues that will break functionality, lose data, or create vulnerabilities. These must be fixed before merge.
- **Moderate risks**: issues likely to cause bugs, confuse maintainers, or create debt. Should be fixed or explicitly accepted.
- **Optional improvements**: style, readability, or defensive additions. Fix if convenient, defer if not.
