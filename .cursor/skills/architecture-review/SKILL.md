---
name: architecture-review
description: Review structure, boundaries, and migration risk before or after major changes.
---

# Architecture Review

## Authority

1. `AGENTS.md`
2. `_system/PROJECT_RULES.md`
3. `_system/EXECUTION_PROTOCOL.md`
4. `_system/review-playbooks/ARCHITECTURE_REVIEW_PLAYBOOK.md`

## Review methodology

### 1. Boundary analysis

Identify every module boundary the change touches. For each boundary:

- **Ownership**: Does this module own its data and logic, or does it reach into another module's internals?
- **Interface surface**: Is the contract explicit (typed exports, API schema) or implicit (shared globals, file conventions)?
- **Coupling direction**: Does the dependency flow one way, or is there circular coupling?
- **Violation test**: Could this module be deleted or replaced without modifying the other side? If not, the boundary is violated.

Flag: direct imports across `_system/` and runtime, shared mutable state between modules, models that leak persistence details into UI layers.

### 2. Contract stability

For every interface that changed:

- Does the change add, modify, or remove a public signature?
- Are all existing callers updated or still compatible?
- Is the change backward-compatible, or does it require a migration?
- Are types, schemas, or validation rules updated in the same pass?

Flag: renamed exports without updating all consumers, changed return types, removed fields from API responses, new required parameters.

### 3. Migration risk assessment

Classify changes by risk level:

- **Low**: config change, new leaf module, additive API field — rollback is trivial.
- **Medium**: refactored internal module, changed data flow, new required dependency — rollback requires coordination.
- **High**: data migration, schema change, auth model change, removed public API — rollback may lose data or break clients.

For medium and high: require an explicit rollback plan or reversibility note.

### 4. Hidden coupling detection

Check for:

- Implicit contracts via naming conventions (file paths, env var names, magic strings).
- Shared infrastructure assumptions (database schemas, queue topics, cache keys).
- Temporal coupling (operations that must happen in a specific order but aren't enforced).
- Build-time coupling (imports that work in dev but break in production bundles).

## Output format

For each finding, report:

- **Severity**: critical / moderate / low
- **Location**: file and function or module
- **Finding**: what the issue is
- **Impact**: what could go wrong
- **Recommendation**: specific corrective action

Output critical boundary violations and migration risks first, then moderate structural concerns, then optional improvements.

## Output

- boundary violations with severity and impact
- migration risk classification (low / medium / high)
- contract drift with affected callers
- hidden coupling findings
- recommended corrective actions with specific locations
