import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  buildExpenseCategoryRollup,
  buildMonthlyIncomeExpenseSeries,
  formatLedgerAmountDisplay,
  rollupCategoryTotals,
} from "./transactionDisplay";
import type { Transaction } from "./ledger.schema";

const baseTxn = (over: Partial<Transaction>): Transaction => ({
  id: "00000000-0000-4000-8000-000000000001",
  householdId: "00000000-0000-4000-8000-000000000002",
  amount: 100,
  date: "2026-05-01T12:00:00.000Z",
  payee: "Test",
  category: "food",
  type: "expense",
  createdAt: "2026-05-01T12:00:00.000Z",
  updatedAt: "2026-05-01T12:00:00.000Z",
  ...over,
});

describe("formatLedgerAmountDisplay", () => {
  it("shows + for income", () => {
    const r = formatLedgerAmountDisplay(42.5, "income");
    expect(r.sign).toBe("+");
    expect(r.currencyBody).toMatch(/42\.50/);
  });

  it("shows - for expense", () => {
    const r = formatLedgerAmountDisplay(10, "expense");
    expect(r.sign).toBe("-");
    expect(r.currencyBody).toContain("10");
  });
});

describe("rollupCategoryTotals", () => {
  it("groups by category and respects type filter", () => {
    const rows: Transaction[] = [
      baseTxn({ id: "00000000-0000-4000-8000-000000000011", category: "food", type: "expense", amount: 10 }),
      baseTxn({ id: "00000000-0000-4000-8000-000000000012", category: "food", type: "expense", amount: 5 }),
      baseTxn({
        id: "00000000-0000-4000-8000-000000000013",
        category: "salary",
        type: "income",
        amount: 1000,
        date: "2026-05-02T12:00:00.000Z",
      }),
    ];
    const exp = rollupCategoryTotals(rows, { type: "expense" });
    expect(exp.food).toEqual({ total: 15, count: 2 });
    expect(exp.salary).toBeUndefined();
  });

  it("uses uncategorized for blank category", () => {
    const rows: Transaction[] = [baseTxn({ category: "  ", id: "00000000-0000-4000-8000-000000000021" })];
    const r = rollupCategoryTotals(rows);
    expect(r.uncategorized.total).toBe(100);
  });
});

describe("buildExpenseCategoryRollup", () => {
  it("sorts by total and folds overflow into Other", () => {
    const rows: Transaction[] = Array.from({ length: 15 }, (_, i) =>
      baseTxn({
        id: `00000000-0000-4000-8000-${String(100 + i).padStart(12, "0")}`,
        category: `c${i}`,
        type: "expense",
        amount: i + 1,
        date: "2026-05-10T12:00:00.000Z",
      })
    );
    const { rows: out, monthTotal } = buildExpenseCategoryRollup(rows, "2026-05", 5);
    expect(out.length).toBeLessThanOrEqual(5);
    expect(monthTotal).toBe(rows.reduce((s, r) => s + r.amount, 0));
    const other = out.find((r) => r.category.startsWith("Other ("));
    expect(other).toBeDefined();
  });

  it("does not add Other when under cap", () => {
    const rows: Transaction[] = [
      baseTxn({ id: "00000000-0000-4000-8000-000000000101", category: "a", amount: 10 }),
      baseTxn({ id: "00000000-0000-4000-8000-000000000102", category: "b", amount: 20, date: "2026-05-11T12:00:00.000Z" }),
    ];
    const { rows: out } = buildExpenseCategoryRollup(rows, "2026-05", 12);
    expect(out.map((r) => r.category).sort()).toEqual(["a", "b"]);
  });
});

describe("buildMonthlyIncomeExpenseSeries", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-05-15T12:00:00.000Z"));
  });
  afterEach(() => {
    vi.useRealTimers();
  });

  it("aggregates income and expenses per calendar month", () => {
    const rows: Transaction[] = [
      baseTxn({
        id: "00000000-0000-4000-8000-000000000031",
        type: "income",
        amount: 3000,
        date: "2026-05-10T12:00:00.000Z",
      }),
      baseTxn({
        id: "00000000-0000-4000-8000-000000000032",
        type: "expense",
        amount: 500,
        date: "2026-05-15T12:00:00.000Z",
      }),
    ];
    const series = buildMonthlyIncomeExpenseSeries(rows, 3);
    const point = series.find((p) => p.income === 3000 && p.expenses === 500);
    expect(point).toBeDefined();
    expect(point!.net).toBe(2500);
  });

  it("accepts date-only ISO strings", () => {
    const rows: Transaction[] = [
      baseTxn({
        id: "00000000-0000-4000-8000-000000000041",
        date: "2026-05-02",
        type: "expense",
        amount: 25,
      }),
    ];
    const series = buildMonthlyIncomeExpenseSeries(rows, 2);
    const point = series.find((p) => p.expenses === 25);
    expect(point).toBeDefined();
  });
});
