/**
 * Synchronous browser `confirm()` for deletes.
 * In React routes, prefer `useDeleteConfirm()` from `../context/DeleteConfirmContext`
 * (`DeleteConfirmProvider` wraps the authenticated app shell) so copy matches Beacon modals.
 *
 * @returns true if the user confirms.
 */
export function confirmEntityDelete(entityLabel: string, displayName?: string): boolean {
  const who = displayName?.trim() ? ` "${displayName.trim()}"` : "";
  return window.confirm(`Delete ${entityLabel}${who}?\n\nThis cannot be undone.`);
}
