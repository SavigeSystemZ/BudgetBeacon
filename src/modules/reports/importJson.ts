import { db } from "../../db/db";
import { z } from "zod";
import { householdSchema, personSchema } from "../household/household.schema";
import { incomeSourceSchema } from "../income/income.schema";
import { billSchema, debtSchema } from "../pay-path/pay-path.schema";
import { savingsGoalSchema } from "../stash-map/stash-map.schema";
import { creditSnapshotSchema } from "../credit/credit.schema";
import { transactionSchema } from "../ledger/ledger.schema";

// We validate the backup file format heavily to prevent corrupted data
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
});

export async function importDatabaseFromJson(file: File): Promise<void> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = async (e) => {
      try {
        const json = JSON.parse(e.target?.result as string);
        const parsed = backupSchema.parse(json); // Validate schema first

        // Execute overwrite within a Dexie transaction for safety
        await db.transaction("rw", 
          [db.households, db.persons, db.incomeSources, db.bills, db.debts, db.savingsGoals, db.creditSnapshots, db.transactions], 
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

            // Insert backup
            await db.households.bulkAdd(parsed.households);
            await db.persons.bulkAdd(parsed.persons);
            await db.incomeSources.bulkAdd(parsed.incomeSources);
            await db.bills.bulkAdd(parsed.bills);
            await db.debts.bulkAdd(parsed.debts);
            await db.savingsGoals.bulkAdd(parsed.savingsGoals);
            await db.creditSnapshots.bulkAdd(parsed.creditSnapshots);
            if (parsed.transactions) await db.transactions.bulkAdd(parsed.transactions);
          }
        );

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
