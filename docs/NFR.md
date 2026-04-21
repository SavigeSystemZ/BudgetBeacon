# Non-Functional Requirements (NFR)

## Privacy
- Strictly local-first.
- No cloud accounts, no credential storage.
- No hidden network calls or default analytics.
- User-controlled JSON export/import for backup.

## Security
- Validate all user inputs via Zod.
- Escape all user-generated text rendered in React (default).
- Confirm all destructive actions (e.g., overwriting data during import, deleting goals).
- Ensure failed imports do not corrupt existing IndexedDB data.

## Reliability
- Data must persist predictably across page reloads.
- The `budget-engine` must elegantly handle empty datasets (no NaN or divide-by-zero crashes).
- Backup export/import must round-trip with 100% fidelity.

## Performance
- The dashboard must recalculate and render instantly for a normal household dataset.
- Budget engine functions must remain pure, deterministic, and fast.