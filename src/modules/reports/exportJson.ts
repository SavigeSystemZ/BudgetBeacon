import { db } from "../../db/db";
import { blobToBase64 } from "../../lib/encoding/base64";

export const BACKUP_FORMAT_VERSION = 3;

/**
 * Backup format history:
 *   v1 — original 8 tables. Lost 10 tables of data on restore.
 *   v2 — adds 9 JSON-serializable tables (M2). Documents (Blob) still excluded.
 *   v3 — adds documents with base64-encoded Blob data (M4).
 *
 * v1 and v2 backups still validate on import (importJson.ts).
 */
export async function buildBackupPayload() {
  // Encode document Blobs to base64 so the payload survives JSON round-trip.
  const documentRows = await db.documents.toArray();
  const documents = await Promise.all(
    documentRows.map(async (doc) => ({
      id: doc.id,
      householdId: doc.householdId,
      personId: doc.personId,
      label: doc.label,
      category: doc.category,
      fileName: doc.fileName,
      fileType: doc.fileType,
      fileSize: doc.fileSize,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
      dataBase64: await blobToBase64(doc.data),
    }))
  );

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
    documents,
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
