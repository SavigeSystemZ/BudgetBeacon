# Performance Review

Run the performance review playbook with budget awareness.

## Authority

- `AGENTS.md`
- `_system/PERFORMANCE_BUDGET.md`
- `_system/review-playbooks/PERFORMANCE_REVIEW_PLAYBOOK.md`
- `_system/PROJECT_PROFILE.md`

## Process

1. Load the performance budget and review playbook.
2. Identify the changed or in-scope code paths.
3. Check for budget violations: bundle size, query patterns, caching, resource cleanup, rendering performance.
4. Report findings using the playbook output format.
5. Fix must-fix issues or record them in `FIXME.md`.
