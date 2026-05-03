/**
 * Ledger display and rollup helpers.
 * Adapted from sibling donor patterns (CouplesWealth transactionHelpers); Budget Beacon
 * uses positive amounts for both income and expense, with type on the row.
 */

import {
  eachMonthOfInterval,
  endOfMonth,
  format,
  parseISO,
  startOfMonth,
  subMonths,
} from "date-fns";
import type { Transaction, TransactionType } from "./ledger.schema";

export interface LedgerAmountDisplay {
  /** Visual sign for list UI */
  sign: "+" | "-";
  /** Currency string without sign (caller may prepend sign) */
  currencyBody: string;
}

/**
 * Format a stored ledger amount for display. Amounts are always positive in DB;
 * sign comes from {@link TransactionType}.
 */
export function formatLedgerAmountDisplay(amount: number, type: TransactionType): LedgerAmountDisplay {
  const currencyBody = amount.toLocaleString(undefined, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
  return {
    sign: type === "income" ? "+" : "-",
    currencyBody: `$${currencyBody}`,
  };
}

export interface CategoryRollupFilters {
  type?: TransactionType;
  /** Inclusive ISO date string compare on `transaction.date` */
  dateFrom?: string;
  dateTo?: string;
  /** Match `transaction.date` prefix e.g. current month `YYYY-MM` */
  monthPrefix?: string;
}

export interface CategoryRollup {
  total: number;
  count: number;
}

/**
 * Sum transaction amounts by category name for the current schema (string category).
 */
export function rollupCategoryTotals(
  transactions: readonly Transaction[],
  filters: CategoryRollupFilters = {}
): Record<string, CategoryRollup> {
  const totals: Record<string, CategoryRollup> = {};

  for (const t of transactions) {
    if (filters.type !== undefined && t.type !== filters.type) continue;
    if (filters.monthPrefix !== undefined && !t.date.startsWith(filters.monthPrefix)) continue;
    if (filters.dateFrom !== undefined && t.date < filters.dateFrom) continue;
    if (filters.dateTo !== undefined && t.date > filters.dateTo) continue;

    const key = t.category.trim() || "uncategorized";
    if (!totals[key]) totals[key] = { total: 0, count: 0 };
    totals[key].total += t.amount;
    totals[key].count += 1;
  }

  return totals;
}

export interface ExpenseCategoryRow {
  category: string;
  total: number;
  count: number;
}

/**
 * Month-to-date expense totals by category, sorted by spend. Surplus categories beyond
 * `maxCategories` are folded into one "Other" row for dense UI (Reports, Mission Control).
 */
export function buildExpenseCategoryRollup(
  transactions: readonly Transaction[],
  monthPrefix: string,
  maxCategories = 12
): { rows: ExpenseCategoryRow[]; monthTotal: number } {
  const rollup = rollupCategoryTotals(transactions, { type: "expense", monthPrefix });
  let entries: ExpenseCategoryRow[] = Object.entries(rollup).map(([category, v]) => ({
    category,
    total: v.total,
    count: v.count,
  }));
  entries.sort((a, b) => b.total - a.total);
  const monthTotal = entries.reduce((s, e) => s + e.total, 0);

  if (entries.length > maxCategories) {
    const head = entries.slice(0, maxCategories - 1);
    const tail = entries.slice(maxCategories - 1);
    entries = [
      ...head,
      {
        category: `Other (${tail.length} categories)`,
        total: tail.reduce((s, r) => s + r.total, 0),
        count: tail.reduce((s, r) => s + r.count, 0),
      },
    ];
  }

  return { rows: entries, monthTotal };
}

export interface MonthlyIncomeExpensePoint {
  month: string;
  fullMonth: string;
  income: number;
  expenses: number;
  net: number;
}

function parseTransactionDate(isoDate: string): Date {
  return parseISO(isoDate.length <= 10 ? `${isoDate}T12:00:00` : isoDate);
}

/**
 * Rolling N calendar months of income vs expense totals (positive numbers).
 */
export function buildMonthlyIncomeExpenseSeries(
  transactions: readonly Transaction[],
  months = 6
): MonthlyIncomeExpensePoint[] {
  const end = new Date();
  const start = subMonths(end, months - 1);
  const monthsRange = eachMonthOfInterval({ start: startOfMonth(start), end: startOfMonth(end) });

  return monthsRange.map((month) => {
    const monthStart = startOfMonth(month);
    const monthEnd = endOfMonth(month);

    const monthTxns = transactions.filter((t) => {
      const date = parseTransactionDate(t.date);
      return date >= monthStart && date <= monthEnd;
    });

    const income = monthTxns.filter((t) => t.type === "income").reduce((sum, t) => sum + t.amount, 0);
    const expenses = monthTxns.filter((t) => t.type === "expense").reduce((sum, t) => sum + t.amount, 0);

    return {
      month: format(month, "MMM"),
      fullMonth: format(month, "MMMM yyyy"),
      income,
      expenses,
      net: income - expenses,
    };
  });
}
