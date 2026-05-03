/**
 * Pure assembly + formatting for the assistant system prompt.
 * DB reads stay in `contextBuilder.ts`; tests hit these functions with fixed clocks.
 */

import type { IncomeSource } from "../income/income.schema";
import type { Bill, Debt } from "../pay-path/pay-path.schema";
import type { SavingsGoal } from "../stash-map/stash-map.schema";
import type { Transaction } from "../ledger/ledger.schema";
import type { CreditSnapshot } from "../credit/credit.schema";
import type { BudgetSummary } from "../budget-engine/budget.types";
import { calculateBudgetSummary } from "../budget-engine/calculateBudgetSummary";
import { calculateStabilityIndex, stabilityBand } from "../budget-engine/stabilityIndex";
import { buildExpenseCategoryRollup } from "../ledger/transactionDisplay";

export type SubscriptionLike = { amount: number; frequency: string };
export type InsuranceLike = { premium?: number };

export interface AssistantPromptFactInputs {
  incomeSources: IncomeSource[];
  bills: Bill[];
  debts: Debt[];
  savingsGoals: SavingsGoal[];
  transactions: Transaction[];
  subscriptions: SubscriptionLike[];
  insuranceRecords: InsuranceLike[];
  creditSnapshots: CreditSnapshot[];
  /** Used for `YYYY-MM` MTD rollup; pass a fixed date in tests. */
  now?: Date;
}

export interface AssistantPromptFacts {
  monthPrefix: string;
  summary: BudgetSummary;
  stabilityIndex: number;
  stabilityLabel: string;
  mtdExpenseTotal: number;
  mtdExpenseRowCount: number;
  mtdExpenseTopCategories: { category: string; total: number }[];
  latestCredit: CreditSnapshot | undefined;
  counts: {
    incomeSources: number;
    bills: number;
    debts: number;
    savingsGoals: number;
    transactions: number;
    subscriptions: number;
    insuranceRecords: number;
    creditSnapshots: number;
  };
}

export function buildAssistantPromptFacts(input: AssistantPromptFactInputs): AssistantPromptFacts {
  const now = input.now ?? new Date();
  const monthPrefix = now.toISOString().slice(0, 7);

  const summary = calculateBudgetSummary(
    input.incomeSources,
    input.bills,
    input.debts,
    input.savingsGoals,
    input.transactions,
    input.subscriptions,
    input.insuranceRecords,
  );

  const stabilityIndex = calculateStabilityIndex(summary);
  const stabilityLabel = stabilityBand(stabilityIndex);

  const { rows: mtdExpenseCats, monthTotal: mtdExpenseTotal } = buildExpenseCategoryRollup(
    input.transactions,
    monthPrefix,
    8,
  );

  const mtdExpenseRowCount = mtdExpenseCats.reduce((n, r) => n + r.count, 0);
  const mtdExpenseTopCategories = mtdExpenseCats.slice(0, 5).map((r) => ({
    category: r.category,
    total: r.total,
  }));

  const latestCredit = [...input.creditSnapshots].sort((a, b) =>
    (b.snapshotDate || "").localeCompare(a.snapshotDate || ""),
  )[0];

  return {
    monthPrefix,
    summary,
    stabilityIndex,
    stabilityLabel,
    mtdExpenseTotal,
    mtdExpenseRowCount,
    mtdExpenseTopCategories,
    latestCredit,
    counts: {
      incomeSources: input.incomeSources.length,
      bills: input.bills.length,
      debts: input.debts.length,
      savingsGoals: input.savingsGoals.length,
      transactions: input.transactions.length,
      subscriptions: input.subscriptions.length,
      insuranceRecords: input.insuranceRecords.length,
      creditSnapshots: input.creditSnapshots.length,
    },
  };
}

const fmtUsd = (n: number) =>
  n.toLocaleString("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 });

/**
 * Deterministic given {@link AssistantPromptFacts}; used as the assistant `system` message body.
 */
export function formatAssistantSystemPrompt(facts: AssistantPromptFacts): string {
  const { summary, stabilityIndex, stabilityLabel, monthPrefix, mtdExpenseTopCategories, mtdExpenseTotal, mtdExpenseRowCount, latestCredit, counts } = facts;

  const lines: string[] = [
    "You are Beacon Agent, a household budgeting assistant.",
    "Be concise. Cite numbers from the snapshot below; do not invent values.",
    "If the user asks for an action that would change their data, tell them which screen to use — never claim you wrote anything yourself.",
    "",
    "Household snapshot (real, current):",
    `- Monthly income: ${fmtUsd(summary.totalMonthlyIncome)} across ${counts.incomeSources} source(s)`,
    `- Monthly bills:  ${fmtUsd(summary.totalMonthlyBills)} across ${counts.bills} bill(s)`,
    `- Monthly debt minimums: ${fmtUsd(summary.totalDebtMinimums)} across ${counts.debts} debt(s)`,
    `- Monthly subscriptions: ${fmtUsd(summary.totalMonthlySubscriptions)} across ${counts.subscriptions} sub(s)`,
    `- Monthly insurance premiums (rolled to monthly): ${fmtUsd(summary.totalMonthlyInsurance)} across ${counts.insuranceRecords} record(s)`,
    `- Required outflow / income: ${(summary.payPathPressureRatio * 100).toFixed(0)}%`,
    `- Leftover after required + savings: ${fmtUsd(summary.leftoverAfterSavings)}`,
    `- Active savings goals: ${counts.savingsGoals} (scheduled ${fmtUsd(summary.totalStashMapScheduled)}/mo)`,
    `- Budget status: ${summary.budgetStatus}`,
    `- Stability index (0-100): ${stabilityIndex} (${stabilityLabel})`,
  ];

  if (mtdExpenseTotal > 0) {
    lines.push(
      `- MTD ledger expenses (${monthPrefix}): ${fmtUsd(mtdExpenseTotal)} across ${mtdExpenseRowCount} expense row(s)`,
    );
    lines.push(
      `- Top expense categories MTD: ${mtdExpenseTopCategories
        .map((r) => `${r.category} ${fmtUsd(r.total)}`)
        .join("; ")}`,
    );
  } else {
    lines.push(`- MTD ledger expenses (${monthPrefix}): none logged (category mix unknown)`);
  }

  if (latestCredit) {
    lines.push(`- Latest credit snapshot: score ${latestCredit.score ?? "?"} on ${latestCredit.snapshotDate}`);
  }

  return lines.join("\n");
}
