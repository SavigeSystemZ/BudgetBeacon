import { describe, it, expect } from "vitest";
import type { IncomeSource } from "../income/income.schema";
import type { Bill } from "../pay-path/pay-path.schema";
import type { Transaction } from "../ledger/ledger.schema";
import type { CreditSnapshot } from "../credit/credit.schema";
import { buildAssistantPromptFacts, formatAssistantSystemPrompt } from "./assistantContextFacts";

const HID = "10101010-1010-4010-8010-101010101010";
const NOW = new Date("2026-06-10T12:00:00.000Z");

const baseIncome: IncomeSource = {
  id: "20202020-2020-4020-8020-202020202020",
  householdId: HID,
  label: "Pay",
  amount: 4000,
  frequency: "monthly",
  isActive: true,
  createdAt: "2026-01-01",
  updatedAt: "2026-01-01",
};

const baseBill: Bill = {
  id: "30303030-3030-4030-8030-303030303030",
  householdId: HID,
  label: "Rent",
  amount: 1000,
  frequency: "monthly",
  category: "housing",
  autopay: true,
  isEssential: true,
  createdAt: "2026-01-01",
  updatedAt: "2026-01-01",
};

function expense(id: string, category: string, amount: number, day: string): Transaction {
  return {
    id,
    householdId: HID,
    amount,
    date: `${day}T12:00:00.000Z`,
    payee: "X",
    category,
    type: "expense",
    createdAt: "2026-06-01T12:00:00.000Z",
    updatedAt: "2026-06-01T12:00:00.000Z",
  };
}

describe("buildAssistantPromptFacts", () => {
  it("uses now for monthPrefix and rolls up MTD expenses", () => {
    const facts = buildAssistantPromptFacts({
      incomeSources: [baseIncome],
      bills: [baseBill],
      debts: [],
      savingsGoals: [],
      transactions: [
        expense("61616161-6161-4161-8161-616161616161", "food", 50, "2026-06-02"),
        expense("62626262-6262-4262-8262-626262626262", "food", 30, "2026-06-03"),
        expense("63636363-6363-4363-8363-636363636363", "gas", 20, "2026-06-04"),
      ],
      subscriptions: [],
      insuranceRecords: [],
      creditSnapshots: [],
      now: NOW,
    });

    expect(facts.monthPrefix).toBe("2026-06");
    expect(facts.mtdExpenseTotal).toBe(100);
    expect(facts.mtdExpenseRowCount).toBe(3);
    expect(facts.mtdExpenseTopCategories[0]?.category).toBe("food");
    expect(facts.mtdExpenseTopCategories[0]?.total).toBe(80);
  });

  it("merges extendedCounts into formatted prompt", () => {
    const facts = buildAssistantPromptFacts({
      incomeSources: [baseIncome],
      bills: [baseBill],
      debts: [],
      savingsGoals: [],
      transactions: [],
      subscriptions: [],
      insuranceRecords: [],
      creditSnapshots: [],
      now: NOW,
      extendedCounts: { taxRecords: 2, taxForms: 1, vaultDocuments: 3, payeeRules: 5 },
    });
    expect(facts.counts.taxRecords).toBe(2);
    expect(facts.counts.taxForms).toBe(1);
    const prompt = formatAssistantSystemPrompt(facts);
    expect(prompt).toContain("Tax year records logged: 2");
    expect(prompt).toContain("Saved tax forms: 1");
    expect(prompt).toContain("Vault documents (local): 3");
    expect(prompt).toContain("Payee rules (import normalization): 5");
  });

  it("picks latest credit snapshot by snapshotDate", () => {
    const older: CreditSnapshot = {
      id: "40404040-4040-4040-8040-404040404040",
      householdId: HID,
      score: 700,
      bureauOrSource: "Old",
      snapshotDate: "2026-01-01",
      createdAt: "2026-01-01",
      updatedAt: "2026-01-01",
    };
    const newer: CreditSnapshot = {
      id: "50505050-5050-4050-8050-505050505050",
      householdId: HID,
      score: 720,
      bureauOrSource: "New",
      snapshotDate: "2026-06-09",
      createdAt: "2026-06-01",
      updatedAt: "2026-06-01",
    };
    const facts = buildAssistantPromptFacts({
      incomeSources: [baseIncome],
      bills: [baseBill],
      debts: [],
      savingsGoals: [],
      transactions: [],
      subscriptions: [],
      insuranceRecords: [],
      creditSnapshots: [older, newer],
      now: NOW,
    });
    expect(facts.latestCredit?.score).toBe(720);
  });
});

describe("formatAssistantSystemPrompt", () => {
  it("includes insurance and MTD lines when spend exists", () => {
    const facts = buildAssistantPromptFacts({
      incomeSources: [baseIncome],
      bills: [baseBill],
      debts: [],
      savingsGoals: [],
      transactions: [expense("64646464-6464-4464-8464-646464646464", "utilities", 45, "2026-06-05")],
      subscriptions: [],
      insuranceRecords: [{ premium: 60 }],
      creditSnapshots: [],
      now: NOW,
    });
    const prompt = formatAssistantSystemPrompt(facts);
    expect(prompt).toContain("Monthly insurance premiums");
    expect(prompt).toContain("MTD ledger expenses (2026-06)");
    expect(prompt).toContain("utilities");
    expect(prompt).not.toContain("MTD ledger expenses (2026-06): none logged");
  });

  it("emits none logged when MTD expense total is zero", () => {
    const facts = buildAssistantPromptFacts({
      incomeSources: [baseIncome],
      bills: [baseBill],
      debts: [],
      savingsGoals: [],
      transactions: [expense("65656565-6565-4565-8565-656565656565", "food", 10, "2026-05-01")],
      subscriptions: [],
      insuranceRecords: [],
      creditSnapshots: [],
      now: NOW,
    });
    const prompt = formatAssistantSystemPrompt(facts);
    expect(prompt).toContain("MTD ledger expenses (2026-06): none logged");
  });
});
