---
name: performance-review
description: Audit changes for performance budget compliance and optimization opportunities
---

# Performance Review Skill

## Authority

- `AGENTS.md`
- `_system/PERFORMANCE_BUDGET.md`
- `_system/review-playbooks/PERFORMANCE_REVIEW_PLAYBOOK.md`
- `_system/PROJECT_PROFILE.md`

## Steps

1. Read `_system/PERFORMANCE_BUDGET.md` and the performance review playbook.
2. Identify the changed code paths and their performance implications.
3. Check against budget categories:
   - Bundle size impact (frontend)
   - Query patterns and N+1 risks (backend)
   - Resource cleanup (connections, listeners, timers)
   - Rendering performance (re-renders, layout thrashing, animation cost)
   - Caching opportunities and invalidation correctness
   - Payload sizes and pagination
   - Lazy loading and code splitting
4. Classify findings as must-fix, should-fix, or monitor.
5. Report using the playbook output format.
6. Record unresolved items in `FIXME.md`.
7. Update `WHERE_LEFT_OFF.md` if the review surfaces significant work.
