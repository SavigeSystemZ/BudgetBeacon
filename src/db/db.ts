import Dexie, { type Table } from "dexie";
import type { Household, Person } from "../modules/household/household.schema";
import type { IncomeSource } from "../modules/income/income.schema";
import type { Bill, Debt } from "../modules/pay-path/pay-path.schema";
import type { SavingsGoal } from "../modules/stash-map/stash-map.schema";
import type { CreditSnapshot } from "../modules/credit/credit.schema";
import type { Transaction } from "../modules/ledger/ledger.schema";

export class BudgetBeaconDatabase extends Dexie {
  households!: Table<Household, string>;
  persons!: Table<Person, string>;
  incomeSources!: Table<IncomeSource, string>;
  bills!: Table<Bill, string>;
  debts!: Table<Debt, string>;
  savingsGoals!: Table<SavingsGoal, string>;
  creditSnapshots!: Table<CreditSnapshot, string>;
  transactions!: Table<Transaction, string>;

  constructor() {
    super("BudgetBeaconDB");
    
    // Schema version 1
    // Primary key is '&id'
    // Indexed fields are typically foreign keys or frequently sorted fields.
    this.version(1).stores({
      households: "&id",
      persons: "&id, householdId",
      incomeSources: "&id, householdId, personId",
      bills: "&id, householdId, ownerPersonId, category, dueDay",
      debts: "&id, householdId, ownerPersonId, category, dueDay",
      savingsGoals: "&id, householdId, category",
      creditSnapshots: "&id, householdId, personId, snapshotDate"
    });

    // Schema version 2: Adding transactions
    this.version(2).stores({
      households: "&id",
      persons: "&id, householdId",
      incomeSources: "&id, householdId, personId",
      bills: "&id, householdId, ownerPersonId, category, dueDay",
      debts: "&id, householdId, ownerPersonId, category, dueDay",
      savingsGoals: "&id, householdId, category",
      creditSnapshots: "&id, householdId, personId, snapshotDate",
      transactions: "&id, householdId, date, category, type"
    });
  }
}

export const db = new BudgetBeaconDatabase();
