import { db } from "../../db/db";

export const BACKUP_FORMAT_VERSION = 2;

// Tables intentionally excluded from JSON backup:
//   - documents: Blob storage (not JSON-serializable without base64; deferred to M4)
export async function buildBackupPayload() {
  return {
    version: BACKUP_FORMAT_VERSION,
    exportedAt: new Date().toISOString(),
    households: await db.households.toArray(),
    persons: await db.persons.toArray(),
    incomeSources: await db.incomeSources.toArray(),
    bills: await db.bills.toArray(),
    debts: await db.debts.toArray(),
    savingsGoals: await db.savingsGoals.toArray(),
    creditSnapshots: await db.creditSnapshots.toArray(),
    transactions: await db.transactions.toArray(),
    debtTransactions: await db.debtTransactions.toArray(),
    taxRecords: await db.taxRecords.toArray(),
    taxTransactions: await db.taxTransactions.toArray(),
    taxForms: await db.taxForms.toArray(),
    aiConfig: await db.aiConfig.toArray(),
    chatMessages: await db.chatMessages.toArray(),
    subscriptions: await db.subscriptions.toArray(),
    insuranceRecords: await db.insuranceRecords.toArray(),
    syncLogs: await db.syncLogs.toArray(),
  };
}

export async function exportDatabaseToJson(): Promise<void> {
  const payload = await buildBackupPayload();
  const jsonString = JSON.stringify(payload, null, 2);
  const blob = new Blob([jsonString], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");

  link.href = url;
  link.download = `budget-beacon-backup-${new Date().toISOString().split("T")[0]}.json`;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}
