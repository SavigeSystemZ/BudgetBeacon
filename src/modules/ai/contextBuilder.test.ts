import { describe, it, expect, beforeEach } from "vitest";
import { db } from "../../db/db";
import { buildAssistantContext, collectAssistantPromptFacts } from "./contextBuilder";
import { formatAssistantSystemPrompt } from "./assistantContextFacts";

async function clearAssistantTables() {
  await db.transaction(
    "rw",
    [
      db.incomeSources,
      db.bills,
      db.debts,
      db.savingsGoals,
      db.transactions,
      db.subscriptions,
      db.insuranceRecords,
      db.creditSnapshots,
    ],
    async () => {
      await Promise.all([
        db.incomeSources.clear(),
        db.bills.clear(),
        db.debts.clear(),
        db.savingsGoals.clear(),
        db.transactions.clear(),
        db.subscriptions.clear(),
        db.insuranceRecords.clear(),
        db.creditSnapshots.clear(),
      ]);
    },
  );
}

describe("buildAssistantContext", () => {
  beforeEach(async () => {
    await clearAssistantTables();
  });

  it("includes insurance, MTD expense total, and top category names", async () => {
    const now = new Date().toISOString();
    const month = new Date().toISOString().slice(0, 7);
    const hid = "11111111-1111-4111-8111-111111111111";
    const pid = "22222222-2222-4222-8222-222222222222";

    await db.incomeSources.add({
      id: "33333333-3333-4333-8333-333333333333",
      householdId: hid,
      personId: pid,
      label: "Salary",
      amount: 5000,
      frequency: "monthly",
      isActive: true,
      createdAt: now,
      updatedAt: now,
    });
    await db.bills.add({
      id: "44444444-4444-4444-8444-444444444444",
      householdId: hid,
      label: "Rent",
      amount: 1500,
      frequency: "monthly",
      category: "housing",
      autopay: true,
      isEssential: true,
      createdAt: now,
      updatedAt: now,
    });
    await db.insuranceRecords.add({
      id: "55555555-5555-4555-8555-555555555555",
      householdId: hid,
      type: "auto",
      expirationDate: "2027-01-01",
      premium: 120,
    });
    await db.transactions.bulkAdd([
      {
        id: "66666666-6666-4666-8666-666666666666",
        householdId: hid,
        amount: 80,
        date: `${month}-02T12:00:00.000Z`,
        payee: "Grocery",
        category: "food",
        type: "expense",
        createdAt: now,
        updatedAt: now,
      },
      {
        id: "77777777-7777-4777-8777-777777777777",
        householdId: hid,
        amount: 20,
        date: `${month}-03T12:00:00.000Z`,
        payee: "Bus",
        category: "transport",
        type: "expense",
        createdAt: now,
        updatedAt: now,
      },
    ]);

    const ctx = await buildAssistantContext();
    const promptFacts = await collectAssistantPromptFacts();

    expect(ctx.systemPrompt).toBe(formatAssistantSystemPrompt(promptFacts));
    expect(ctx.facts.topExpenseCategories.length).toBeGreaterThan(0);
    expect(ctx.systemPrompt).toContain("Monthly insurance premiums");
    expect(ctx.systemPrompt).toContain(`MTD ledger expenses (${month})`);
    expect(ctx.systemPrompt).toContain("food");
    expect(ctx.systemPrompt).toContain("transport");
    expect(ctx.systemPrompt).toContain("Top expense categories MTD");
  });
});
