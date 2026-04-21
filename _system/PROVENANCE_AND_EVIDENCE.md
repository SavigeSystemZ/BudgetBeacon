# Provenance And Evidence

Use this file to keep generated artifacts, changes, and handoffs auditable.

## Minimum provenance

- tool or agent name
- timestamp
- input objective
- files changed
- validation commands and outcomes

## Stronger provenance

- artifact hashes
- run identifiers
- correlation IDs for elevated actions
- links to reports or generated evidence

## Rules

- Record diff/merge decisions when combining multiple sources.
- Keep immutable evidence where the project requires it.
- If user edits or agent edits materially change an artifact, record the new version rather than silently mutating history.
- Do not let confidence claims outrun recorded evidence in `WHERE_LEFT_OFF.md` or `_system/context/CURRENT_STATUS.md`.
