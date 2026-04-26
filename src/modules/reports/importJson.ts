import { db } from "../../db/db";
import { z } from "zod";
import { householdSchema, personSchema } from "../household/household.schema";
import { incomeSourceSchema } from "../income/income.schema";
import { billSchema, debtSchema } from "../pay-path/pay-path.schema";
import { savingsGoalSchema } from "../stash-map/stash-map.schema";
import { creditSnapshotSchema } from "../credit/credit.schema";
import { transactionSchema } from "../ledger/ledger.schema";
import { base64ToBlob } from "../../lib/encoding/base64";

// Minimal schemas for tables that don't have dedicated schema files yet.
// Strict enough to reject obvious garbage; loose enough to accept evolving shapes.
const debtTransactionSchema = z.object({
  id: z.string(),
  debtId: z.string(),
  amount: z.number(),
  date: z.string(),
  type: z.string(),
});

const taxRecordSchema = z.object({
  id: z.string(),
  householdId: z.string(),
  year: z.number(),
  estimatedTaxLiability: z.number(),
  totalWithheld: z.number(),
  status: z.string(),
  notes: z.string().optional(),
  personId: z.string(),
});

const taxTransactionSchema = z.object({
  id: z.string(),
  recordId: z.string(),
  amount: z.number(),
  date: z.string(),
  type: z.string(),
});

const taxFormSchema = z.object({
  id: z.string(),
  year: z.number(),
  type: z.string(),
  data: z.record(z.string(), z.unknown()),
  updatedAt: z.string(),
  personId: z.string(),
});

const aiConfigSchema = z.object({
  id: z.string(),
  provider: z.enum(["local", "api"]),
  apiKey: z.string().optional(),
  localEndpoint: z.string().optional(),
  model: z.string().optional(),
});

const chatMessageSchema = z.object({
  id: z.string(),
  role: z.enum(["user", "assistant"]),
  content: z.string(),
  timestamp: z.string(),
});

const subscriptionSchema = z.object({
  id: z.string(),
  householdId: z.string(),
  label: z.string(),
  amount: z.number(),
  frequency: z.string(),
  category: z.string(),
  nextRenewal: z.string().optional(),
  supportEmail: z.string().optional(),
  personId: z.string(),
});

const insuranceRecordSchema = z.object({
  id: z.string(),
  householdId: z.string(),
  type: z.string(),
  expirationDate: z.string(),
  premium: z.number().optional(),
});

const syncLogSchema = z.object({
  id: z.string(),
  timestamp: z.string(),
  deviceId: z.string(),
  payloadSize: z.number(),
});

// v3 documents row: Blob is base64-encoded for JSON survival.
const documentBackupSchema = z.object({
  id: z.string(),
  householdId: z.string(),
  personId: z.string(),
  label: z.string(),
  category: z.string(),
  fileName: z.string(),
  fileType: z.string(),
  fileSize: z.number(),
  createdAt: z.string(),
  updatedAt: z.string(),
  dataBase64: z.string(),
});

// v1: 8 tables. v2: +9 JSON-serializable tables. v3: +documents (base64).
// All optional fields make older versions valid on import.
const backupSchema = z.object({
  version: z.number().min(1),
  exportedAt: z.string(),
  households: z.array(householdSchema),
  persons: z.array(personSchema),
  incomeSources: z.array(incomeSourceSchema),
  bills: z.array(billSchema),
  debts: z.array(debtSchema),
  savingsGoals: z.array(savingsGoalSchema),
  creditSnapshots: z.array(creditSnapshotSchema),
  transactions: z.array(transactionSchema).optional(),
  // v2 tables
  debtTransactions: z.array(debtTransactionSchema).optional(),
  taxRecords: z.array(taxRecordSchema).optional(),
  taxTransactions: z.array(taxTransactionSchema).optional(),
  taxForms: z.array(taxFormSchema).optional(),
  aiConfig: z.array(aiConfigSchema).optional(),
  chatMessages: z.array(chatMessageSchema).optional(),
  subscriptions: z.array(subscriptionSchema).optional(),
  insuranceRecords: z.array(insuranceRecordSchema).optional(),
  syncLogs: z.array(syncLogSchema).optional(),
  // v3 tables
  documents: z.array(documentBackupSchema).optional(),
});

export type BackupPayload = z.infer<typeof backupSchema>;

export async function applyBackupPayload(parsed: BackupPayload): Promise<void> {
  // Decode document Blobs outside the Dexie transaction (atob isn't async but
  // keeping the encode/decode logic at the boundary keeps the txn pure-IDB).
  const decodedDocuments = parsed.documents?.map((d) => ({
    id: d.id,
    householdId: d.householdId,
    personId: d.personId,
    label: d.label,
    category: d.category,
    fileName: d.fileName,
    fileType: d.fileType,
    fileSize: d.fileSize,
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
    data: base64ToBlob(d.dataBase64, d.fileType),
  }));

  await db.transaction(
    "rw",
    [
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
    ],
    async () => {
      // Clear existing
      await db.households.clear();
      await db.persons.clear();
      await db.incomeSources.clear();
      await db.bills.clear();
      await db.debts.clear();
      await db.savingsGoals.clear();
      await db.creditSnapshots.clear();
      await db.transactions.clear();
      await db.debtTransactions.clear();
      await db.taxRecords.clear();
      await db.taxTransactions.clear();
      await db.taxForms.clear();
      await db.aiConfig.clear();
      await db.chatMessages.clear();
      await db.subscriptions.clear();
      await db.insuranceRecords.clear();
      await db.syncLogs.clear();
      await db.documents.clear();

      // Insert backup (each non-baseline table optional for older-version compat)
      await db.households.bulkAdd(parsed.households);
      await db.persons.bulkAdd(parsed.persons);
      await db.incomeSources.bulkAdd(parsed.incomeSources);
      await db.bills.bulkAdd(parsed.bills);
      await db.debts.bulkAdd(parsed.debts);
      await db.savingsGoals.bulkAdd(parsed.savingsGoals);
      await db.creditSnapshots.bulkAdd(parsed.creditSnapshots);
      if (parsed.transactions) await db.transactions.bulkAdd(parsed.transactions);
      if (parsed.debtTransactions) await db.debtTransactions.bulkAdd(parsed.debtTransactions);
      if (parsed.taxRecords) await db.taxRecords.bulkAdd(parsed.taxRecords);
      if (parsed.taxTransactions) await db.taxTransactions.bulkAdd(parsed.taxTransactions);
      if (parsed.taxForms) await db.taxForms.bulkAdd(parsed.taxForms);
      if (parsed.aiConfig) await db.aiConfig.bulkAdd(parsed.aiConfig);
      if (parsed.chatMessages) await db.chatMessages.bulkAdd(parsed.chatMessages);
      if (parsed.subscriptions) await db.subscriptions.bulkAdd(parsed.subscriptions);
      if (parsed.insuranceRecords) await db.insuranceRecords.bulkAdd(parsed.insuranceRecords);
      if (parsed.syncLogs) await db.syncLogs.bulkAdd(parsed.syncLogs);
      if (decodedDocuments) await db.documents.bulkAdd(decodedDocuments);
    }
  );
}

/**
 * Returns row counts per table from a parsed backup payload. Used by the
 * restore-confirmation diff preview to tell the user what's about to land
 * before they commit.
 */
export type BackupRowCounts = Record<string, number>;

export function backupRowCounts(parsed: BackupPayload): BackupRowCounts {
  return {
    households: parsed.households.length,
    persons: parsed.persons.length,
    incomeSources: parsed.incomeSources.length,
    bills: parsed.bills.length,
    debts: parsed.debts.length,
    savingsGoals: parsed.savingsGoals.length,
    creditSnapshots: parsed.creditSnapshots.length,
    transactions: parsed.transactions?.length ?? 0,
    debtTransactions: parsed.debtTransactions?.length ?? 0,
    taxRecords: parsed.taxRecords?.length ?? 0,
    taxTransactions: parsed.taxTransactions?.length ?? 0,
    taxForms: parsed.taxForms?.length ?? 0,
    aiConfig: parsed.aiConfig?.length ?? 0,
    chatMessages: parsed.chatMessages?.length ?? 0,
    subscriptions: parsed.subscriptions?.length ?? 0,
    insuranceRecords: parsed.insuranceRecords?.length ?? 0,
    syncLogs: parsed.syncLogs?.length ?? 0,
    documents: parsed.documents?.length ?? 0,
  };
}

/**
 * Returns current row counts from the live db. Used alongside `backupRowCounts`
 * to compute "will replace X, will add Y" diffs in the restore preview.
 */
export async function currentDbRowCounts(): Promise<BackupRowCounts> {
  return {
    households: await db.households.count(),
    persons: await db.persons.count(),
    incomeSources: await db.incomeSources.count(),
    bills: await db.bills.count(),
    debts: await db.debts.count(),
    savingsGoals: await db.savingsGoals.count(),
    creditSnapshots: await db.creditSnapshots.count(),
    transactions: await db.transactions.count(),
    debtTransactions: await db.debtTransactions.count(),
    taxRecords: await db.taxRecords.count(),
    taxTransactions: await db.taxTransactions.count(),
    taxForms: await db.taxForms.count(),
    aiConfig: await db.aiConfig.count(),
    chatMessages: await db.chatMessages.count(),
    subscriptions: await db.subscriptions.count(),
    insuranceRecords: await db.insuranceRecords.count(),
    syncLogs: await db.syncLogs.count(),
    documents: await db.documents.count(),
  };
}

export function parseBackupJson(jsonText: string): BackupPayload {
  const json = JSON.parse(jsonText);
  return backupSchema.parse(json);
}

export async function importDatabaseFromJson(file: File): Promise<void> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = async (e) => {
      try {
        const parsed = parseBackupJson(e.target?.result as string);
        await applyBackupPayload(parsed);
        resolve();
      } catch (error) {
        console.error("Backup import failed:", error);
        reject(error instanceof Error ? error : new Error("Failed to import valid JSON backup"));
      }
    };

    reader.onerror = () => reject(new Error("Failed to read file"));
    reader.readAsText(file);
  });
}
