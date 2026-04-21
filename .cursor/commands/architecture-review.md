Review the current design or diff against:

1. `_system/PROJECT_RULES.md`
2. `_system/EXECUTION_PROTOCOL.md`
3. `_system/review-playbooks/ARCHITECTURE_REVIEW_PLAYBOOK.md`
4. `_system/REPO_BOUNDARY_AND_BACKUP.md`

For every touched module boundary, check:

- Is the boundary self-contained (either side can change internals independently)?
- Are all public contracts (types, schemas, exports) still in sync with consumers?
- Does the dependency direction make sense, or is there circular or upward coupling?
- Are there implicit contracts (magic strings, naming conventions, file-path assumptions)?

Classify migration risk for each architectural change:

- Low: config changes, additive fields, new leaf modules.
- Medium: refactored internals, changed data flow, new required dependencies.
- High: schema migrations, auth changes, removed APIs — require rollback plan.

Output structural risks, boundary violations, and migration concerns first. Then moderate coupling issues. Style or naming last.
