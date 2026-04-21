import { db } from "./db";
import { createId } from "../lib/ids/createId";
import type { Household, Person } from "../modules/household/household.schema";
import type { IncomeSource } from "../modules/income/income.schema";
import type { Bill, Debt } from "../modules/pay-path/pay-path.schema";
import type { SavingsGoal } from "../modules/stash-map/stash-map.schema";

export async function seedDemoData() {
  const householdCount = await db.households.count();
  if (householdCount > 0) {
    console.log("Database already seeded or has data. Skipping demo seed.");
    return;
  }

  console.log("Seeding demo data...");

  const householdId = createId();
  const personId1 = createId();
  const personId2 = createId();
  const now = new Date().toISOString();

  const household: Household = {
    id: householdId,
    name: "Smith Household",
    currency: "USD",
    createdAt: now,
    updatedAt: now,
  };

  const persons: Person[] = [
    { id: personId1, householdId, name: "Alice", role: "primary", createdAt: now, updatedAt: now },
    { id: personId2, householdId, name: "Bob", role: "partner", createdAt: now, updatedAt: now },
  ];

  const incomeSources: IncomeSource[] = [
    { id: createId(), householdId, personId: personId1, label: "Tech Job", amount: 4000, frequency: "monthly", isActive: true, createdAt: now, updatedAt: now },
    { id: createId(), householdId, personId: personId2, label: "Consulting", amount: 1500, frequency: "biweekly", isActive: true, createdAt: now, updatedAt: now },
  ];

  const bills: Bill[] = [
    { id: createId(), householdId, label: "Rent", category: "housing", amount: 2000, frequency: "monthly", dueDay: 1, autopay: true, isEssential: true, createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Electric", category: "utilities", amount: 150, frequency: "monthly", dueDay: 15, autopay: true, isEssential: true, createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Internet", category: "utilities", amount: 80, frequency: "monthly", dueDay: 20, autopay: true, isEssential: true, createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Netflix", category: "subscriptions", amount: 20, frequency: "monthly", dueDay: 10, autopay: false, isEssential: false, createdAt: now, updatedAt: now },
  ];

  const debts: Debt[] = [
    { id: createId(), householdId, label: "Student Loan", creditor: "Navient", balance: 15000, minimumPayment: 250, dueDay: 5, category: "student", priority: "medium", createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Car Loan", creditor: "Chase", balance: 8000, minimumPayment: 300, dueDay: 12, category: "auto", priority: "high", createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Credit Card", creditor: "Amex", balance: 2500, minimumPayment: 75, dueDay: 28, category: "credit-card", priority: "high", createdAt: now, updatedAt: now },
  ];

  const savingsGoals: SavingsGoal[] = [
    { id: createId(), householdId, label: "Emergency Fund", targetAmount: 10000, currentAmount: 3500, monthlyContribution: 500, category: "emergency", priority: "high", createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Vacation", targetAmount: 3000, currentAmount: 500, monthlyContribution: 200, category: "vacation", priority: "low", createdAt: now, updatedAt: now },
  ];

  await db.transaction("rw", [db.households, db.persons, db.incomeSources, db.bills, db.debts, db.savingsGoals], async () => {
    await db.households.add(household);
    await db.persons.bulkAdd(persons);
    await db.incomeSources.bulkAdd(incomeSources);
    await db.bills.bulkAdd(bills);
    await db.debts.bulkAdd(debts);
    await db.savingsGoals.bulkAdd(savingsGoals);
  });

  console.log("Demo data seeded successfully.");
}

export async function clearDatabase() {
  console.log("Clearing database...");
  await db.transaction("rw", [db.households, db.persons, db.incomeSources, db.bills, db.debts, db.savingsGoals, db.creditSnapshots], async () => {
    await db.households.clear();
    await db.persons.clear();
    await db.incomeSources.clear();
    await db.bills.clear();
    await db.debts.clear();
    await db.savingsGoals.clear();
    await db.creditSnapshots.clear();
  });
  console.log("Database cleared.");
}
