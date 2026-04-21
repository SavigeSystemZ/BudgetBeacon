---
name: dependency-review
description: Review dependency changes for security, license compliance, size impact, and necessity
---

# Dependency Review Skill

## Authority

- `AGENTS.md`
- `_system/DEPENDENCY_GOVERNANCE.md`
- `_system/review-playbooks/DEPENDENCY_REVIEW_PLAYBOOK.md`
- `_system/PROJECT_PROFILE.md`

## Steps

1. Read `_system/DEPENDENCY_GOVERNANCE.md` and the dependency review playbook.
2. Identify new, updated, or removed dependencies from changed manifests and lockfiles.
3. For each new dependency, evaluate:
   - Necessity (can it be done with existing deps or stdlib?)
   - Maintenance health (last release, issue responsiveness)
   - Security (known CVEs, supply chain history)
   - License compatibility
   - Bundle size and transitive dependency impact
   - API stability and semver adherence
4. For updated dependencies, review changelogs for breaking changes.
5. Classify findings as must-fix, should-fix, or informational.
6. Report using the playbook output format.
7. Record unresolved items in `FIXME.md`.
