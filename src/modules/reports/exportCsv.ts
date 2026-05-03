import { db } from "../../db/db";
import { rowsToCsv, downloadTextFile, type CsvCell } from "../../lib/csv/csv";
import type { Transaction } from "../ledger/ledger.schema";
import type { Bill, Debt } from "../pay-path/pay-path.schema";
import type { SavingsGoal } from "../stash-map/stash-map.schema";
import type { CreditSnapshot } from "../credit/credit.schema";
import { buildExpenseCategoryRollup } from "../ledger/transactionDisplay";

/** Dexie rows may carry optional `personId` not present on the Zod schema. */
function transactionCsvPersonId(row: Transaction): string {
  const r = row as Transaction & { personId?: string };
  return typeof r.personId === "string" ? r.personId : "";
}

const dateStamp = () => new Date().toISOString().split("T")[0];

export type CsvEntity =
  | "transactions"
  | "bills"
  | "debts"
  | "savingsGoals"
  | "subscriptions"
  | "insurance"
  | "creditSnapshots"
  | "expenseCategoriesMtd";

const NAME_TO_FILENAME: Record<CsvEntity, string> = {
  transactions: "transactions",
  bills: "bills",
  debts: "debts",
  savingsGoals: "savings-goals",
  subscriptions: "subscriptions",
  insurance: "insurance",
  creditSnapshots: "credit-snapshots",
  expenseCategoriesMtd: "expense-categories-mtd",
};

export async function buildCsvForEntity(entity: CsvEntity): Promise<{ filename: string; csv: string; rowCount: number }> {
  const filename = `budget-beacon-${NAME_TO_FILENAME[entity]}-${dateStamp()}.csv`;
  switch (entity) {
    case "transactions": {
      const rows = await db.transactions.orderBy("date").toArray();
      const headers = ["date", "type", "payee", "amount", "category", "personId", "id"];
      const data: CsvCell[][] = rows.map((t) => [
        t.date,
        t.type,
        t.payee,
        t.amount,
        t.category,
        transactionCsvPersonId(t),
        t.id,
      ]);
      return { filename, csv: rowsToCsv(headers, data), rowCount: rows.length };
    }
    case "bills": {
      const rows = await db.bills.toArray();
      const headers = ["label", "amount", "frequency", "category", "dueDay", "autopay", "isEssential", "ownerPersonId", "id"];
      const data: CsvCell[][] = rows.map((b: Bill) => [
        b.label,
        b.amount,
        b.frequency,
        b.category,
        b.dueDay ?? "",
        b.autopay,
        b.isEssential,
        b.ownerPersonId ?? "",
        b.id,
      ]);
      return { filename, csv: rowsToCsv(headers, data), rowCount: rows.length };
    }
    case "debts": {
      const rows = await db.debts.toArray();
      const headers = ["label", "balance", "minimumPayment", "category", "priority", "ownerPersonId", "id"];
      const data: CsvCell[][] = rows.map((d: Debt) => [
        d.label,
        d.balance,
        d.minimumPayment,
        d.category,
        d.priority,
        d.ownerPersonId ?? "",
        d.id,
      ]);
      return { filename, csv: rowsToCsv(headers, data), rowCount: rows.length };
    }
    case "savingsGoals": {
      const rows = await db.savingsGoals.toArray();
      const headers = ["label", "targetAmount", "currentAmount", "monthlyContribution", "category", "priority", "id"];
      const data: CsvCell[][] = rows.map((g: SavingsGoal) => [
        g.label,
        g.targetAmount,
        g.currentAmount,
        g.monthlyContribution,
        g.category,
        g.priority,
        g.id,
      ]);
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
      const data: CsvCell[][] = rows.map((s: CreditSnapshot) => [
        s.snapshotDate,
        s.score,
        s.bureauOrSource,
        s.personId ?? "",
        s.id,
      ]);
      return { filename, csv: rowsToCsv(headers, data), rowCount: rows.length };
    }
    case "expenseCategoriesMtd": {
      const rows = await db.transactions.toArray();
      const month = new Date().toISOString().slice(0, 7);
      const { rows: catRows, monthTotal } = buildExpenseCategoryRollup(rows, month, 50);
      const headers = ["month", "category", "total_spend", "transaction_count", "month_expense_total"];
      const data: CsvCell[][] = catRows.map((r) => [month, r.category, r.total, r.count, monthTotal]);
      return { filename, csv: rowsToCsv(headers, data), rowCount: catRows.length };
    }
  }
}

export async function downloadCsvForEntity(entity: CsvEntity): Promise<{ filename: string; rowCount: number }> {
  const { filename, csv, rowCount } = await buildCsvForEntity(entity);
  downloadTextFile(filename, csv);
  return { filename, rowCount };
}
