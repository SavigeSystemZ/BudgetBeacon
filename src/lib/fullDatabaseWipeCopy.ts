/**
 * Beacon modal strings for destructive full-database actions.
 * Operational scope matches `clearDatabase()` → `clearFullDatabase()` / `fullDatabaseRwScope()`.
 */

export const FULL_WIPE_MODAL_TITLE = "Wipe entire database?";

/** Primary body paragraph; pair with FULL_WIPE_EXPORT_HINT and CANNOT_UNDONE_SHORT in UI. */
export const FULL_WIPE_SCOPE_DESCRIPTION =
  "This clears every local Dexie store — households, Vault documents, ledger & payee rules, subscriptions, insurance, Beacon chat, tax records & forms, AI config rows in the DB, debts, savings goals — the same IndexedDB footprint as a backup restore that replaces all data.";

export const FULL_WIPE_EXPORT_HINT = "Export a backup from Settings first if you might want anything back.";

export const CANNOT_UNDONE_SHORT = "This cannot be undone.";

export const DEMO_RESET_MODAL_TITLE = "Reset to demo data?";

export const DEMO_RESET_DESCRIPTION =
  "Performs a full wipe (same scope as above), then loads the bundled demo seed so you start from the curated sample household. Use this only if you intend to discard your current data.";
