import { db } from "../../db/db";
import {
  buildAssistantPromptFacts,
  formatAssistantSystemPrompt,
  type AssistantPromptFacts,
} from "./assistantContextFacts";

export type { AssistantPromptFacts } from "./assistantContextFacts";
export { buildAssistantPromptFacts, formatAssistantSystemPrompt } from "./assistantContextFacts";

/**
 * Build a compact, factual system prompt grounding the assistant in real db
 * data. Keep it small — large contexts slow local models. Anything the user
 * specifically asks about can come from a follow-up query.
 *
 * The prompt is intentionally read-only. The assistant must NOT propose
 * or perform db writes; that lands in M7.2 with an explicit confirmation UI.
 */

export type AssistantContextFacts = {
  monthlyIncome: number;
  monthlyBills: number;
  monthlyDebtMin: number;
  monthlySubs: number;
  monthlyInsurance: number;
  netMonthly: number;
  activeGoals: number;
  stabilityIndex: number;
  stabilityLabel: string;
  monthPrefix: string;
  mtdExpenseTotal: number;
  mtdExpenseRowCount: number;
  topExpenseCategories: { category: string; total: number }[];
  budgetStatus: "GREEN" | "YELLOW" | "RED";
  /** Count aggregates for modules outside the budget summary engine — same Dexie-backed truth as Tax Taxi / Vault / import rules */
  taxRecordCount: number;
  taxFormCount: number;
  vaultDocumentCount: number;
  payeeRuleCount: number;
};

export interface AssistantContextSnapshot {
  systemPrompt: string;
  facts: AssistantContextFacts;
}

function toContextFacts(f: AssistantPromptFacts): AssistantContextFacts {
  return {
    monthlyIncome: f.summary.totalMonthlyIncome,
    monthlyBills: f.summary.totalMonthlyBills,
    monthlyDebtMin: f.summary.totalDebtMinimums,
    monthlySubs: f.summary.totalMonthlySubscriptions,
    monthlyInsurance: f.summary.totalMonthlyInsurance,
    netMonthly: f.summary.leftoverAfterSavings,
    activeGoals: f.counts.savingsGoals,
    stabilityIndex: f.stabilityIndex,
    stabilityLabel: f.stabilityLabel,
    monthPrefix: f.monthPrefix,
    mtdExpenseTotal: f.mtdExpenseTotal,
    mtdExpenseRowCount: f.mtdExpenseRowCount,
    topExpenseCategories: f.mtdExpenseTopCategories,
    budgetStatus: f.summary.budgetStatus,
    taxRecordCount: f.counts.taxRecords,
    taxFormCount: f.counts.taxForms,
    vaultDocumentCount: f.counts.vaultDocuments,
    payeeRuleCount: f.counts.payeeRules,
  };
}

/**
 * Loads Dexie tables and returns structured facts (no string formatting).
 * Useful for tests and any UI that wants the same numbers as the assistant.
 */
export async function collectAssistantPromptFacts(options?: {
  now?: Date;
}): Promise<AssistantPromptFacts> {
  const [
    incomeSources,
    bills,
    debts,
    savingsGoals,
    transactions,
    subscriptions,
    insuranceRecords,
    creditSnapshots,
    taxRecordsCount,
    taxFormsCount,
    vaultDocumentsCount,
    payeeRulesCount,
  ] = await Promise.all([
    db.incomeSources.toArray(),
    db.bills.toArray(),
    db.debts.toArray(),
    db.savingsGoals.toArray(),
    db.transactions.toArray(),
    db.subscriptions.toArray(),
    db.insuranceRecords.toArray(),
    db.creditSnapshots.toArray(),
    db.taxRecords.count(),
    db.taxForms.count(),
    db.documents.count(),
    db.payeeRules.count(),
  ]);

  return buildAssistantPromptFacts({
    incomeSources,
    bills,
    debts,
    savingsGoals,
    transactions,
    subscriptions,
    insuranceRecords,
    creditSnapshots,
    now: options?.now,
    extendedCounts: {
      taxRecords: taxRecordsCount,
      taxForms: taxFormsCount,
      vaultDocuments: vaultDocumentsCount,
      payeeRules: payeeRulesCount,
    },
  });
}

export async function buildAssistantContext(options?: { now?: Date }): Promise<AssistantContextSnapshot> {
  const promptFacts = await collectAssistantPromptFacts(options);
  return {
    systemPrompt: formatAssistantSystemPrompt(promptFacts),
    facts: toContextFacts(promptFacts),
  };
}
