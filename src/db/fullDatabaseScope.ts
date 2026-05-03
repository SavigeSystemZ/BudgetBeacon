import { db } from "./db";

/**
 * Every persistent IndexedDB store (Dexie v5). Single source of truth for
 * full wipes and backup-restore reset — keep in sync when schema migrations add tables.
 */
export function fullDatabaseRwScope() {
  return [
    db.households,
    db.persons,
    db.incomeSources,
    db.bills,
    db.debts,
    db.savingsGoals,
    db.creditSnapshots,
    db.transactions,
    db.debtTransactions,
    db.taxRecords,
    db.taxTransactions,
    db.taxForms,
    db.aiConfig,
    db.chatMessages,
    db.subscriptions,
    db.insuranceRecords,
    db.syncLogs,
    db.documents,
    db.payeeRules,
  ] as const;
}

export async function clearFullDatabase(): Promise<void> {
  const scope = fullDatabaseRwScope();
  await db.transaction("rw", [...scope], async () => {
    await Promise.all(scope.map((t) => t.clear()));
  });
}
