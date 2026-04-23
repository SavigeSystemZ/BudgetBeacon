import { db } from "./db";

export async function seedDemoData() {
  const householdCount = await db.households.count();
  if (householdCount > 0) {
    console.log("Database already seeded or has data. Skipping demo seed.");
    return;
  }

  console.log("Seeding from va-assistance-seed.json...");
  
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

    console.log("VA data seeded successfully.");
  } catch (error) {
    console.error("Error seeding VA data:", error);
  }
}

export async function clearDatabase() {
  console.log("Clearing database...");
  await db.transaction("rw", [db.households, db.persons, db.incomeSources, db.bills, db.debts, db.savingsGoals, db.creditSnapshots, db.transactions], async () => {
    await db.households.clear();
    await db.persons.clear();
    await db.incomeSources.clear();
    await db.bills.clear();
    await db.debts.clear();
    await db.savingsGoals.clear();
    await db.creditSnapshots.clear();
    await db.transactions.clear();
  });
  console.log("Database cleared.");
}
