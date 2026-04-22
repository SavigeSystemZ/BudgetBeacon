import fs from "fs";
import path from "path";
import { createId } from "../src/lib/ids/createId";
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Read raw file
const rawPath = path.resolve(__dirname, "../public/va-assistance-raw.json");
const rawData = JSON.parse(fs.readFileSync(rawPath, "utf-8"));

const householdId = createId();
const now = new Date().toISOString();

// Transform logic
const household = {
  id: householdId,
  name: "Spaulding Household",
  currency: "USD",
  createdAt: now,
  updatedAt: now,
};

const persons = rawData.profiles.map(p => ({
  id: p.person_id,
  householdId,
  name: p.legal_name,
  role: p.role === "applicant_account_holder" ? "primary" : "partner",
  createdAt: now,
  updatedAt: now
}));

const incomeSources = [];
rawData.income_monthly.self.forEach(i => {
  incomeSources.push({
    id: createId(),
    householdId,
    personId: "self_michael",
    label: i.category,
    amount: i.amount,
    frequency: "monthly",
    isActive: true,
    createdAt: now,
    updatedAt: now
  });
});
rawData.income_monthly.partner.forEach(i => {
  incomeSources.push({
    id: createId(),
    householdId,
    personId: "partner_kehley",
    label: i.category,
    amount: i.amount,
    frequency: "monthly",
    isActive: true,
    createdAt: now,
    updatedAt: now
  });
});

const bills = [];
const addBills = (arr, categoryName) => {
  arr.forEach(i => {
    if (i.amount > 0) {
      bills.push({
        id: createId(),
        householdId,
        label: i.category,
        category: categoryName,
        amount: i.amount,
        frequency: "monthly",
        dueDay: 1, // Defaulting to 1 as raw data has no due days
        autopay: false,
        isEssential: true,
        createdAt: now,
        updatedAt: now
      });
    }
  });
};

addBills(rawData.expenses_monthly.housing_and_property, "housing");
addBills(rawData.expenses_monthly.utilities, "utilities");
addBills(rawData.expenses_monthly.transportation, "transportation");
addBills(rawData.expenses_monthly.food_household_pet, "personal"); // Note: there's no exact 'food' in standard, 'personal' is safe. Wait, our schema might support 'food', so let's stick to simple ones.
// Let's manually map these to standard string categories 

const debts = [];
rawData.expenses_monthly.debts_loans_and_rentals.forEach(d => {
    if (d.amount > 0) {
        debts.push({
            id: createId(),
            householdId,
            label: d.category,
            creditor: d.category.split(" ")[0],
            balance: 0,
            minimumPayment: d.amount,
            dueDay: 1,
            category: "personal",
            priority: "medium",
            createdAt: now,
            updatedAt: now
        })
    }
});

rawData.arrears_and_balances.forEach(a => {
   debts.push({
        id: createId(),
        householdId,
        label: `${a.account} Arrears`,
        creditor: a.account,
        balance: a.balance_or_amount_due,
        minimumPayment: a.monthly_payment || 0,
        dueDay: 1,
        category: "utilities", // Mostly utilities
        priority: "high",
        createdAt: now,
        updatedAt: now
   });
});

const savingsGoals = rawData.stash_map_goals.map(g => ({
    id: createId(),
    householdId,
    label: g.goal,
    targetAmount: g.target_total,
    currentAmount: 0,
    monthlyContribution: g.target_monthly,
    category: "emergency",
    priority: "high",
    createdAt: now,
    updatedAt: now
}));

const payload = {
  version: 1,
  exportedAt: now,
  households: [household],
  persons: persons,
  incomeSources: incomeSources,
  bills: bills,
  debts: debts,
  savingsGoals: savingsGoals,
  creditSnapshots: []
};

const outputPath = path.resolve(__dirname, "../public/va-assistance-seed.json");
fs.writeFileSync(outputPath, JSON.stringify(payload, null, 2), "utf-8");
console.log(`Successfully generated importable JSON: ${outputPath}`);
