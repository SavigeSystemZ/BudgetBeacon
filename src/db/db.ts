import Dexie, { type Table } from "dexie";
import type { Household, Person } from "../modules/household/household.schema";
import type { IncomeSource } from "../modules/income/income.schema";
import type { Bill, Debt } from "../modules/pay-path/pay-path.schema";
import type { SavingsGoal } from "../modules/stash-map/stash-map.schema";
import type { Transaction } from "../modules/ledger/ledger.schema";
import type { CreditSnapshot } from "../modules/credit/credit.schema";

/** User-managed merchant/payee normalization rule. Applied during CSV import. */
export interface PayeeRule {
  id: string;
  householdId: string;
  /** Lower-cased substring or exact-match key. */
  pattern: string;
  /** "contains" matches if the normalized payee contains the pattern; "exact" requires equality. */
  matchType: "contains" | "exact";
  /** Replace the payee field on match. Optional — when omitted, only category is set. */
  payeeOverride?: string;
  /** One of the bill/transaction categories. */
  category?: string;
  createdAt: string;
  updatedAt: string;
}

export class BudgetBeaconDatabase extends Dexie {
  households!: Table<Household, string>;
  persons!: Table<Person, string>;
  incomeSources!: Table<IncomeSource, string>;
  bills!: Table<Bill, string>;
  debts!: Table<Debt, string>;
  savingsGoals!: Table<SavingsGoal, string>;
  creditSnapshots!: Table<CreditSnapshot, string>;
  transactions!: Table<Transaction, string>;
  debtTransactions!: Table<{ id: string; debtId: string; amount: number; date: string; type: string }, string>;
  taxRecords!: Table<{ id: string; householdId: string; year: number; estimatedTaxLiability: number; totalWithheld: number; status: string; notes?: string; personId: string }, string>;
  taxTransactions!: Table<{ id: string; recordId: string; amount: number; date: string; type: string }, string>;
  documents!: Table<{ id: string; householdId: string; label: string; category: string; fileName: string; fileType: string; fileSize: number; data: Blob; createdAt: string; updatedAt: string; personId: string }, string>;
  aiConfig!: Table<{ id: string; provider: "local" | "api"; apiKey?: string; localEndpoint?: string; model?: string }, string>;
  chatMessages!: Table<{ id: string; role: "user" | "assistant"; content: string; timestamp: string }, string>;
  taxForms!: Table<{ id: string; year: number; type: string; data: Record<string, unknown>; updatedAt: string; personId: string }, string>;
  subscriptions!: Table<{ id: string; householdId: string; label: string; amount: number; frequency: string; category: string; nextRenewal?: string; supportEmail?: string; personId: string }, string>;
  insuranceRecords!: Table<{ id: string; householdId: string; type: string; expirationDate: string; premium?: number }, string>;
  syncLogs!: Table<{ id: string; timestamp: string; deviceId: string; payloadSize: number }, string>;
  payeeRules!: Table<PayeeRule, string>;

  constructor() {
    super("BudgetBeaconDB");
    
    this.version(1).stores({
      households: "&id",
      persons: "&id, householdId",
      incomeSources: "&id, householdId, personId",
      bills: "&id, householdId, ownerPersonId, category, dueDay",
      debts: "&id, householdId, ownerPersonId, category, dueDay",
      savingsGoals: "&id, householdId, category",
      creditSnapshots: "&id, householdId, personId, snapshotDate"
    });

    this.version(2).stores({
      households: "&id",
      persons: "&id, householdId",
      incomeSources: "&id, householdId, personId",
      bills: "&id, householdId, ownerPersonId, category, dueDay",
      debts: "&id, householdId, ownerPersonId, category, dueDay",
      savingsGoals: "&id, householdId, category",
      creditSnapshots: "&id, householdId, personId, snapshotDate",
      transactions: "&id, householdId, date, category, type",
      debtTransactions: "&id, debtId, date",
      taxRecords: "&id, householdId, year",
      taxTransactions: "&id, recordId, date"
    });

    this.version(3).stores({
      households: "&id",
      persons: "&id, householdId",
      incomeSources: "&id, householdId, personId",
      bills: "&id, householdId, ownerPersonId, category, dueDay",
      debts: "&id, householdId, ownerPersonId, category, dueDay",
      savingsGoals: "&id, householdId, category",
      creditSnapshots: "&id, householdId, personId, snapshotDate",
      transactions: "&id, householdId, date, category, type",
      debtTransactions: "&id, debtId, date",
      taxRecords: "&id, householdId, year",
      taxTransactions: "&id, recordId, date",
      documents: "&id, householdId, category",
      aiConfig: "&id",
      chatMessages: "&id, timestamp",
      taxForms: "&id, year, type"
    });

    this.version(5).stores({
      households: "&id",
      persons: "&id, householdId",
      incomeSources: "&id, householdId, personId",
      bills: "&id, householdId, ownerPersonId, category, dueDay",
      debts: "&id, householdId, ownerPersonId, category, dueDay",
      savingsGoals: "&id, householdId, category",
      creditSnapshots: "&id, householdId, personId, snapshotDate",
      transactions: "&id, householdId, date, category, type, personId",
      debtTransactions: "&id, debtId, date",
      taxRecords: "&id, householdId, year, personId",
      taxTransactions: "&id, recordId, date",
      documents: "&id, householdId, category, personId",
      aiConfig: "&id",
      chatMessages: "&id, timestamp",
      taxForms: "&id, year, type, personId",
      subscriptions: "&id, householdId, category, personId",
      insuranceRecords: "&id, householdId, type, expirationDate",
      syncLogs: "&id, timestamp, deviceId",
      payeeRules: "&id, householdId, pattern",
    });

    this.version(4).stores({
      households: "&id",
      persons: "&id, householdId",
      incomeSources: "&id, householdId, personId",
      bills: "&id, householdId, ownerPersonId, category, dueDay",
      debts: "&id, householdId, ownerPersonId, category, dueDay",
      savingsGoals: "&id, householdId, category",
      creditSnapshots: "&id, householdId, personId, snapshotDate",
      transactions: "&id, householdId, date, category, type, personId",
      debtTransactions: "&id, debtId, date",
      taxRecords: "&id, householdId, year, personId",
      taxTransactions: "&id, recordId, date",
      documents: "&id, householdId, category, personId",
      aiConfig: "&id",
      chatMessages: "&id, timestamp",
      taxForms: "&id, year, type, personId",
      subscriptions: "&id, householdId, category, personId",
      insuranceRecords: "&id, householdId, type, expirationDate",
      syncLogs: "&id, timestamp, deviceId"
    });
  }
}

export const db = new BudgetBeaconDatabase();
