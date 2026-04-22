import "fake-indexeddb/auto";
import { db } from "../src/db/db";
import { createId } from "../src/lib/ids/createId";
import type { Household, Person } from "../src/modules/household/household.schema";
import type { IncomeSource } from "../src/modules/income/income.schema";
import type { Bill, Debt } from "../src/modules/pay-path/pay-path.schema";
import type { SavingsGoal } from "../src/modules/stash-map/stash-map.schema";

export async function importVAData() {
  const householdId = createId();
  const personIdMichael = "self_michael";
  const personIdKehley = "partner_kehley";
  const now = new Date().toISOString();

  const household: Household = {
    id: householdId,
    name: "Spaulding Household",
    currency: "USD",
    createdAt: now,
    updatedAt: now,
  };

  const persons: Person[] = [
    { id: personIdMichael, householdId, name: "Michael Todd Spaulding", role: "primary", createdAt: now, updatedAt: now },
    { id: personIdKehley, householdId, name: "Kehley M. Smith", role: "partner", createdAt: now, updatedAt: now },
  ];

  const incomeSources: IncomeSource[] = [
    { id: createId(), householdId, personId: personIdMichael, label: "Social Security / SSDI", amount: 2140.0, frequency: "monthly", isActive: true, createdAt: now, updatedAt: now },
    { id: createId(), householdId, personId: personIdMichael, label: "VA Disability Compensation", amount: 552.47, frequency: "monthly", isActive: true, createdAt: now, updatedAt: now },
    { id: createId(), householdId, personId: personIdKehley, label: "Net Wages - Market Basket dairy stocker (Estimated)", amount: 1300.0, frequency: "monthly", isActive: true, createdAt: now, updatedAt: now },
    { id: createId(), householdId, personId: personIdKehley, label: "Food Stamps / SNAP (Estimated)", amount: 75.0, frequency: "monthly", isActive: true, createdAt: now, updatedAt: now },
  ];

  const bills: Bill[] = [
    // Housing
    { id: createId(), householdId, label: "Property Taxes", category: "housing", amount: 550.0, frequency: "monthly", dueDay: 1, autopay: false, isEssential: true, createdAt: now, updatedAt: now },
    // Utilities
    { id: createId(), householdId, label: "Electricity - Eversource payment plan", category: "utilities", amount: 665.0, frequency: "monthly", dueDay: 1, autopay: false, isEssential: true, createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Internet - DS", category: "utilities", amount: 65.0, frequency: "monthly", dueDay: 1, autopay: false, isEssential: true, createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Cell Phone", category: "utilities", amount: 40.0, frequency: "monthly", dueDay: 1, autopay: false, isEssential: true, createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Trash Disposal", category: "utilities", amount: 75.0, frequency: "monthly", dueDay: 1, autopay: false, isEssential: true, createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Wood/Pellets Heat", category: "utilities", amount: 175.0, frequency: "monthly", dueDay: 1, autopay: false, isEssential: true, createdAt: now, updatedAt: now },
    // Transportation
    { id: createId(), householdId, label: "Auto Payment/Lease", category: "transportation", amount: 300.0, frequency: "monthly", dueDay: 1, autopay: false, isEssential: true, createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Auto Insurance - USAA", category: "transportation", amount: 30.15, frequency: "monthly", dueDay: 1, autopay: false, isEssential: true, createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Auto Fuel", category: "transportation", amount: 217.0, frequency: "monthly", dueDay: 1, autopay: false, isEssential: true, createdAt: now, updatedAt: now },
    // Food/Household
    { id: createId(), householdId, label: "Groceries / Food", category: "food", amount: 800.0, frequency: "monthly", dueDay: 1, autopay: false, isEssential: true, createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Household Supplies", category: "personal", amount: 217.0, frequency: "monthly", dueDay: 1, autopay: false, isEssential: true, createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Pet Food/Care", category: "personal", amount: 104.0, frequency: "monthly", dueDay: 1, autopay: false, isEssential: true, createdAt: now, updatedAt: now },
    // Subscriptions/Discretionary
    { id: createId(), householdId, label: "SimpliSafe", category: "subscriptions", amount: 30.0, frequency: "monthly", dueDay: 1, autopay: false, isEssential: false, createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Subscriptions (Amazon/AI)", category: "subscriptions", amount: 100.0, frequency: "monthly", dueDay: 1, autopay: false, isEssential: false, createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Dining Out", category: "food", amount: 50.0, frequency: "monthly", dueDay: 1, autopay: false, isEssential: false, createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Clothing", category: "personal", amount: 25.0, frequency: "monthly", dueDay: 1, autopay: false, isEssential: false, createdAt: now, updatedAt: now }
  ];

  const debts: Debt[] = [
    { id: createId(), householdId, label: "Rent-A-Center", creditor: "Rent-A-Center", balance: 0, minimumPayment: 230.0, dueDay: 1, category: "personal", priority: "high", createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Aaron's", creditor: "Aaron's", balance: 0, minimumPayment: 400.0, dueDay: 1, category: "personal", priority: "high", createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Family Debt Repayment", creditor: "Family", balance: 400.0, minimumPayment: 100.0, dueDay: 1, category: "personal", priority: "medium", createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Partner Student Loans", creditor: "Student Loan", balance: 0, minimumPayment: 200.0, dueDay: 1, category: "student", priority: "medium", createdAt: now, updatedAt: now },
    // Balances/Arrears tracking
    { id: createId(), householdId, label: "Eversource Arrears", creditor: "Eversource", balance: 5248.58, minimumPayment: 0, dueDay: 1, category: "utilities", priority: "high", createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Trash Arrears", creditor: "Trash", balance: 165.0, minimumPayment: 0, dueDay: 1, category: "utilities", priority: "medium", createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Applicant collections", creditor: "Collections", balance: 2000.0, minimumPayment: 0, dueDay: 1, category: "personal", priority: "low", createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Partner collections", creditor: "Collections", balance: 2000.0, minimumPayment: 0, dueDay: 1, category: "personal", priority: "low", createdAt: now, updatedAt: now }
  ];

  const savingsGoals: SavingsGoal[] = [
    { id: createId(), householdId, label: "Electric payment gap reserve", targetAmount: 795.0, currentAmount: 0, monthlyContribution: 265.0, category: "emergency", priority: "high", createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Winter pellet reserve", targetAmount: 900.0, currentAmount: 0, monthlyContribution: 75.0, category: "housing", priority: "medium", createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Trash arrears payoff", targetAmount: 165.0, currentAmount: 0, monthlyContribution: 30.0, category: "emergency", priority: "medium", createdAt: now, updatedAt: now },
    { id: createId(), householdId, label: "Emergency utility/transport buffer", targetAmount: 300.0, currentAmount: 0, monthlyContribution: 25.0, category: "emergency", priority: "low", createdAt: now, updatedAt: now }
  ];

  await db.transaction("rw", [db.households, db.persons, db.incomeSources, db.bills, db.debts, db.savingsGoals], async () => {
    await db.households.add(household);
    await db.persons.bulkAdd(persons);
    await db.incomeSources.bulkAdd(incomeSources);
    await db.bills.bulkAdd(bills);
    await db.debts.bulkAdd(debts);
    await db.savingsGoals.bulkAdd(savingsGoals);
  });

  console.log("VA Data seeded successfully.");
}

importVAData().catch(console.error);
