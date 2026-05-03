import { describe, it, expect, beforeEach } from "vitest";
import { db } from "../../db/db";
import { buildCsvForEntity } from "./exportCsv";

describe("buildCsvForEntity", () => {
  beforeEach(async () => {
    await db.transactions.clear();
  });

  it("builds expenseCategoriesMtd csv from ledger expenses", async () => {
    const now = new Date().toISOString();
    const month = new Date().toISOString().slice(0, 7);
    const hid = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";
    await db.transactions.bulkAdd([
      {
        id: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
        householdId: hid,
        amount: 40,
        date: `${month}-08T12:00:00.000Z`,
        payee: "Shop",
        category: "food",
        type: "expense",
        createdAt: now,
        updatedAt: now,
      },
      {
        id: "cccccccc-cccc-4ccc-8ccc-cccccccccccc",
        householdId: hid,
        amount: 25,
        date: `${month}-09T12:00:00.000Z`,
        payee: "Fuel",
        category: "transport",
        type: "expense",
        createdAt: now,
        updatedAt: now,
      },
    ]);

    const { csv, rowCount, filename } = await buildCsvForEntity("expenseCategoriesMtd");
    expect(rowCount).toBe(2);
    expect(filename).toContain("expense-categories-mtd");
    expect(csv).toContain(month);
    expect(csv).toContain("food");
    expect(csv).toContain("transport");
    expect(csv).toContain("65");
  });
});
