import { db } from "../../db/db";
import { z } from "zod";
import { householdSchema, personSchema } from "../household/household.schema";
import { incomeSourceSchema } from "../income/income.schema";
import { billSchema, debtSchema } from "../pay-path/pay-path.schema";
import { savingsGoalSchema } from "../stash-map/stash-map.schema";
import { creditSnapshotSchema } from "../credit/credit.schema";
import { transactionSchema } from "../ledger/ledger.schema";

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

// v1 backups had only 8 tables. v2 adds the remaining JSON-serializable tables.
// `documents` (Blob) is excluded from both versions; deferred to M4.
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
  // v2 tables (optional so v1 backups still validate)
  debtTransactions: z.array(debtTransactionSchema).optional(),
  taxRecords: z.array(taxRecordSchema).optional(),
  taxTransactions: z.array(taxTransactionSchema).optional(),
  taxForms: z.array(taxFormSchema).optional(),
  aiConfig: z.array(aiConfigSchema).optional(),
  chatMessages: z.array(chatMessageSchema).optional(),
  subscriptions: z.array(subscriptionSchema).optional(),
  insuranceRecords: z.array(insuranceRecordSchema).optional(),
  syncLogs: z.array(syncLogSchema).optional(),
});

export type BackupPayload = z.infer<typeof backupSchema>;

export async function applyBackupPayload(parsed: BackupPayload): Promise<void> {
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

      // Insert backup (each table optional for v1 backwards-compat)
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
    }
  );
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
