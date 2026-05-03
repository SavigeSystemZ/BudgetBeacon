import { describe, it, expect, beforeEach } from "vitest";
import { db } from "./db";
import { clearDatabase } from "./seedDemoData";

describe("clearDatabase", () => {
  beforeEach(async () => {
    await clearDatabase();
  });

  it("clears every store so the app can return to empty state", async () => {
    const now = new Date().toISOString();
    const hid = "11111111-1111-4111-8111-111111111111";
    await db.households.add({ id: hid, name: "H", currency: "USD", createdAt: now, updatedAt: now });
    await db.payeeRules.add({
      id: "22222222-2222-4222-8222-222222222222",
      householdId: hid,
      pattern: "amazon",
      matchType: "contains",
      category: "other",
      createdAt: now,
      updatedAt: now,
    });
    await db.chatMessages.add({
      id: "33333333-3333-4333-8333-333333333333",
      role: "user",
      content: "hi",
      timestamp: now,
    });

    expect(await db.households.count()).toBe(1);
    expect(await db.payeeRules.count()).toBe(1);
    expect(await db.chatMessages.count()).toBe(1);

    await clearDatabase();

    expect(await db.households.count()).toBe(0);
    expect(await db.payeeRules.count()).toBe(0);
    expect(await db.chatMessages.count()).toBe(0);
  });
});
