# Architecture Review Playbook

## Review inputs

- `ARCHITECTURE_NOTES.md`
- `_system/PROJECT_PROFILE.md`
- `_system/context/ARCHITECTURAL_INVARIANTS.md`
- the touched code and contract surface

## Review checklist

### Layer separation

- [ ] Runtime code does not import from or depend on `_system/`.
- [ ] System files do not reach into runtime internals.
- [ ] Module boundaries are explicit in filesystem structure (each module owns its directory).
- [ ] No circular dependencies between modules.

### Contract stability

- [ ] Public interfaces (types, schemas, exports, API routes) are still in sync with all consumers.
- [ ] Changed signatures have updated callers in the same pass.
- [ ] Removed or renamed exports have no remaining references.
- [ ] Schema changes have corresponding migration or versioning.

### Data flow clarity

- [ ] The path from input to output is traceable without jumping across unrelated modules.
- [ ] Transformations happen at the appropriate layer (not in the wrong module).
- [ ] Side effects are intentional, localized, and documented.
- [ ] Shared mutable state is avoided or explicitly managed.

### Coupling assessment

- [ ] Each module can be changed internally without modifying other modules.
- [ ] No implicit contracts (magic strings, naming conventions used as API, file-path assumptions).
- [ ] Infrastructure assumptions (database schemas, queue topics, cache keys) are encapsulated.
- [ ] Temporal coupling (operations that must happen in order) is enforced, not assumed.

### Migration risk

Classify each architectural change:

- **Low**: config change, additive API field, new leaf module — rollback is trivial.
- **Medium**: refactored internals, changed data flow, new required dependency — rollback requires coordination.
- **High**: data migration, schema change, auth model change, removed public API — rollback may lose data or break clients.

For medium and high risk: verify a rollback plan or reversibility note exists.

## Must-fix findings

- runtime now depends on `_system/`
- contract or schema change without corresponding docs or tests
- behavior spread across unrelated layers without intent
- a new abstraction increases coupling more than it reduces complexity
- circular dependency introduced between modules
- high-risk migration without rollback plan

## Output format

For each finding, report:

- **Severity**: critical / moderate / low
- **Location**: module, file, and function
- **Finding**: what the issue is
- **Impact**: what could go wrong
- **Recommendation**: specific corrective action

Output in this order:

1. Critical boundary violations and data-integrity risks
2. Contract drift and missing consumer updates
3. Structural risks and coupling concerns
4. Accepted tradeoffs (with rationale)
5. Follow-up architecture notes to record
