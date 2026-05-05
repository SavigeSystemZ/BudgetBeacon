import { db } from "./db";
import { clearFullDatabase } from "./fullDatabaseScope";
import { logger } from "../lib/logger";

/**
 * Loads bundled demo fixtures when **no households** exist (e.g. fresh install).
 * To replace existing data with demo, callers must **`clearDatabase()`** first —
 * Settings “Reset to demo” does exactly that before calling this function.
 */
export async function seedDemoData() {
  const householdCount = await db.households.count();
  if (householdCount > 0) {
    logger.info("Database already seeded or has data. Skipping demo seed.");
    return;
  }

  logger.info("Seeding from va-assistance-seed.json...");

  try {
    // Note: base path './' in Vite ensures this resolves correctly in Capacitor
    const response = await fetch("./va-assistance-seed.json");
    if (!response.ok) throw new Error("Failed to load seed data");
    const data = await response.json();

    await db.transaction("rw", [db.households, db.persons, db.incomeSources, db.bills, db.debts, db.savingsGoals, db.creditSnapshots, db.transactions], async () => {
      if (data.households) await db.households.bulkAdd(data.households);
      if (data.persons) await db.persons.bulkAdd(data.persons);
      if (data.incomeSources) await db.incomeSources.bulkAdd(data.incomeSources);
      if (data.bills) await db.bills.bulkAdd(data.bills);
      if (data.debts) await db.debts.bulkAdd(data.debts);
      if (data.savingsGoals) await db.savingsGoals.bulkAdd(data.savingsGoals);
      if (data.creditSnapshots) await db.creditSnapshots.bulkAdd(data.creditSnapshots);
      if (data.transactions) await db.transactions.bulkAdd(data.transactions);
    });

    logger.info("VA data seeded successfully.");
  } catch (error) {
    logger.error("Error seeding VA data:", error);
  }
}

export async function ensureHousehold() {
  const householdCount = await db.households.count();
  if (householdCount === 0) {
    const householdId = "default-household";
    const personId = "default-person";
    const now = new Date().toISOString();
    
    await db.households.add({
      id: householdId,
      name: "My Household",
      currency: "USD",
      createdAt: now,
      updatedAt: now,
    });

    await db.persons.add({
      id: personId,
      householdId,
      name: "Primary Member",
      role: "primary",
      createdAt: now,
      updatedAt: now,
    });
    logger.info("Default household created.");
  }
}

/**
 * Wipes every local table (same coverage as backup restore reset). Callers should reload
 * the app if they need onboarding or empty-shell UX to re-run.
 */
export async function clearDatabase() {
  logger.info("Clearing database...");
  await clearFullDatabase();
  logger.info("Database cleared.");
}

/** Full IndexedDB wipe + bundled VA demo JSON (Settings “Reset to demo”). Reload the app afterward if UI must re-mount. */
export async function resetToBundledDemo(): Promise<void> {
  await clearDatabase();
  await seedDemoData();
}
