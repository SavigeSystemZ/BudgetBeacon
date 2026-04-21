---
name: code-quality-review
description: Review code changes for adherence to coding standards, clean code principles, and anti-pattern avoidance
---

# Code Quality Review Skill

## Authority

- `AGENTS.md`
- `_system/CODING_STANDARDS.md`
- `_system/review-playbooks/CODE_QUALITY_REVIEW_PLAYBOOK.md`
- `_system/PROJECT_RULES.md`

## Steps

1. Read `_system/CODING_STANDARDS.md` and the code quality review playbook.
2. Review changed files systematically:
   - Naming clarity and conventions
   - Function design (SRP, length, parameters)
   - Error handling (boundary handling, typed errors, context)
   - Resource management (cleanup, cancellation, bounded collections)
   - Type safety (strong types, no unnecessary `any`)
   - Data validation (boundary validation, schema use, sanitization)
   - Async correctness (awaiting, timeouts, cancellation)
   - Test coverage (new behavior tested, modified behavior updated)
3. Check for anti-patterns from the coding standards.
4. Classify findings as must-fix, should-fix, or suggestion.
5. Report using the playbook output format.
6. Record unresolved items in `FIXME.md`.
