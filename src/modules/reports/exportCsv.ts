import { db } from "../../db/db";
import { rowsToCsv, downloadTextFile, type CsvCell } from "../../lib/csv/csv";

const dateStamp = () => new Date().toISOString().split("T")[0];

export type CsvEntity =
  | "transactions"
  | "bills"
  | "debts"
  | "savingsGoals"
  | "subscriptions"
  | "insurance"
  | "creditSnapshots";

const NAME_TO_FILENAME: Record<CsvEntity, string> = {
  transactions: "transactions",
  bills: "bills",
  debts: "debts",
  savingsGoals: "savings-goals",
  subscriptions: "subscriptions",
  insurance: "insurance",
  creditSnapshots: "credit-snapshots",
};

export async function buildCsvForEntity(entity: CsvEntity): Promise<{ filename: string; csv: string; rowCount: number }> {
  const filename = `budget-beacon-${NAME_TO_FILENAME[entity]}-${dateStamp()}.csv`;
  switch (entity) {
    case "transactions": {
      const rows = await db.transactions.orderBy("date").toArray();
      const headers = ["date", "type", "payee", "amount", "category", "personId", "id"];
      const data: CsvCell[][] = rows.map((t) => [t.date, t.type, t.payee, t.amount, t.category, (t as any).personId ?? "", t.id]);
      return { filename, csv: rowsToCsv(headers, data), rowCount: rows.length };
    }
    case "bills": {
      const rows = await db.bills.toArray();
      const headers = ["label", "amount", "frequency", "category", "dueDay", "autopay", "isEssential", "ownerPersonId", "id"];
      const data: CsvCell[][] = rows.map((b) => [b.label, b.amount, b.frequency, b.category, (b as any).dueDay ?? "", (b as any).autopay ?? "", (b as any).isEssential ?? "", (b as any).ownerPersonId ?? "", b.id]);
      return { filename, csv: rowsToCsv(headers, data), rowCount: rows.length };
    }
    case "debts": {
      const rows = await db.debts.toArray();
      const headers = ["label", "balance", "minimumPayment", "category", "priority", "ownerPersonId", "id"];
      const data: CsvCell[][] = rows.map((d) => [d.label, d.balance, d.minimumPayment, d.category, (d as any).priority ?? "", (d as any).ownerPersonId ?? "", d.id]);
      return { filename, csv: rowsToCsv(headers, data), rowCount: rows.length };
    }
    case "savingsGoals": {
      const rows = await db.savingsGoals.toArray();
      const headers = ["label", "targetAmount", "currentAmount", "monthlyContribution", "category", "priority", "id"];
      const data: CsvCell[][] = rows.map((g) => [g.label, g.targetAmount, g.currentAmount, g.monthlyContribution, g.category, (g as any).priority ?? "", g.id]);
      return { filename, csv: rowsToCsv(headers, data), rowCount: rows.length };
    }
    case "subscriptions": {
      const rows = await db.subscriptions.toArray();
      const headers = ["label", "amount", "frequency", "category", "nextRenewal", "supportEmail", "personId", "id"];
      const data: CsvCell[][] = rows.map((s) => [s.label, s.amount, s.frequency, s.category, s.nextRenewal ?? "", s.supportEmail ?? "", s.personId, s.id]);
      return { filename, csv: rowsToCsv(headers, data), rowCount: rows.length };
    }
    case "insurance": {
      const rows = await db.insuranceRecords.toArray();
      const headers = ["type", "premium", "expirationDate", "id"];
      const data: CsvCell[][] = rows.map((p) => [p.type, p.premium ?? 0, p.expirationDate, p.id]);
      return { filename, csv: rowsToCsv(headers, data), rowCount: rows.length };
    }
    case "creditSnapshots": {
      const rows = await db.creditSnapshots.toArray();
      const headers = ["snapshotDate", "score", "bureauOrSource", "personId", "id"];
      const data: CsvCell[][] = rows.map((s) => [s.snapshotDate, s.score, (s as any).bureauOrSource ?? "", s.personId, s.id]);
      return { filename, csv: rowsToCsv(headers, data), rowCount: rows.length };
    }
  }
}

export async function downloadCsvForEntity(entity: CsvEntity): Promise<{ filename: string; rowCount: number }> {
  const { filename, csv, rowCount } = await buildCsvForEntity(entity);
  downloadTextFile(filename, csv);
  return { filename, rowCount };
}
