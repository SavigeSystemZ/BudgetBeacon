import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { db } from "./db";
import { clearDatabase, resetToBundledDemo } from "./seedDemoData";

/** Minimal shape `seedDemoData` accepts when `./va-assistance-seed.json` is mocked. */
const DEMO_FIXTURE_STUB = {
  households: [
    {
      id: "demo-household-fixture",
      name: "Bundled Fixture Household",
      currency: "USD",
      createdAt: "2026-01-01T00:00:00.000Z",
      updatedAt: "2026-01-01T00:00:00.000Z",
    },
  ],
  persons: [
    {
      id: "demo-person-fixture",
      householdId: "demo-household-fixture",
      name: "Fixture Member",
      role: "primary" as const,
      createdAt: "2026-01-01T00:00:00.000Z",
      updatedAt: "2026-01-01T00:00:00.000Z",
    },
  ],
  incomeSources: [] as unknown[],
  bills: [] as unknown[],
  debts: [] as unknown[],
  savingsGoals: [] as unknown[],
  creditSnapshots: [] as unknown[],
  transactions: [] as unknown[],
};

describe("resetToBundledDemo", () => {
  beforeEach(async () => {
    await clearDatabase();
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("wipes existing rows then inserts demo fixture from fetch(json)", async () => {
    const hid = "11111111-1111-4111-8111-111111111111";
    const now = new Date().toISOString();
    await db.households.add({ id: hid, name: "Wipe-me", currency: "USD", createdAt: now, updatedAt: now });

    vi.stubGlobal(
      "fetch",
      vi.fn(async () => ({
        ok: true,
        json: async () => DEMO_FIXTURE_STUB,
      })),
    );

    await resetToBundledDemo();

    expect(await db.households.count()).toBe(1);
    const h = await db.households.toCollection().first();
    expect(h?.id).toBe("demo-household-fixture");
    expect(h?.name).toBe("Bundled Fixture Household");
    expect(await db.persons.count()).toBe(1);
  });
});
