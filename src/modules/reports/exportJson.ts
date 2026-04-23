import { db } from "../../db/db";

export async function exportDatabaseToJson(): Promise<void> {
  const exportData = {
    version: 1,
    exportedAt: new Date().toISOString(),
    households: await db.households.toArray(),
    persons: await db.persons.toArray(),
    incomeSources: await db.incomeSources.toArray(),
    bills: await db.bills.toArray(),
    debts: await db.debts.toArray(),
    savingsGoals: await db.savingsGoals.toArray(),
    creditSnapshots: await db.creditSnapshots.toArray(),
    transactions: await db.transactions.toArray(),
  };

  const jsonString = JSON.stringify(exportData, null, 2);
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
