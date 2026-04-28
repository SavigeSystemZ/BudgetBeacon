import { db } from "../../db/db";
import { calculateBudgetSummary } from "../budget-engine/calculateBudgetSummary";
import { calculateStabilityIndex, stabilityBand } from "../budget-engine/stabilityIndex";

/**
 * Build a compact, factual system prompt grounding the assistant in real db
 * data. Keep it small — large contexts slow local models. Anything the user
 * specifically asks about can come from a follow-up query.
 *
 * The prompt is intentionally read-only. The assistant must NOT propose
 * or perform db writes; that lands in M7.2 with an explicit confirmation UI.
 */

export interface AssistantContextSnapshot {
  systemPrompt: string;
  facts: {
    monthlyIncome: number;
    monthlyBills: number;
    monthlyDebtMin: number;
    monthlySubs: number;
    netMonthly: number;
    activeGoals: number;
    stabilityIndex: number;
    stabilityLabel: string;
  };
}

export async function buildAssistantContext(): Promise<AssistantContextSnapshot> {
  const [
    incomeSources,
    bills,
    debts,
    savingsGoals,
    transactions,
    subscriptions,
    creditSnapshots,
  ] = await Promise.all([
    db.incomeSources.toArray(),
    db.bills.toArray(),
    db.debts.toArray(),
    db.savingsGoals.toArray(),
    db.transactions.toArray(),
    db.subscriptions.toArray(),
    db.creditSnapshots.toArray(),
  ]);

  const summary = calculateBudgetSummary(
    incomeSources,
    bills,
    debts,
    savingsGoals,
    transactions,
    subscriptions,
    [],
  );

  const stability = calculateStabilityIndex(summary);
  const label = stabilityBand(stability);

  const latestCredit = [...creditSnapshots].sort((a, b) =>
    (b.snapshotDate || "").localeCompare(a.snapshotDate || ""),
  )[0];

  const fmt = (n: number) =>
    n.toLocaleString("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 });

  const lines: string[] = [
    "You are Beacon Agent, a household budgeting assistant.",
    "Be concise. Cite numbers from the snapshot below; do not invent values.",
    "If the user asks for an action that would change their data, tell them which screen to use — never claim you wrote anything yourself.",
    "",
    "Household snapshot (real, current):",
    `- Monthly income: ${fmt(summary.totalMonthlyIncome)} across ${incomeSources.length} source(s)`,
    `- Monthly bills:  ${fmt(summary.totalMonthlyBills)} across ${bills.length} bill(s)`,
    `- Monthly debt minimums: ${fmt(summary.totalDebtMinimums)} across ${debts.length} debt(s)`,
    `- Monthly subscriptions: ${fmt(summary.totalMonthlySubscriptions)} across ${subscriptions.length} sub(s)`,
    `- Required outflow / income: ${(summary.payPathPressureRatio * 100).toFixed(0)}%`,
    `- Leftover after required + savings: ${fmt(summary.leftoverAfterSavings)}`,
    `- Active savings goals: ${savingsGoals.length} (scheduled ${fmt(summary.totalStashMapScheduled)}/mo)`,
    `- Budget status: ${summary.budgetStatus}`,
    `- Stability index (0-100): ${stability} (${label})`,
  ];

  if (latestCredit) {
    lines.push(`- Latest credit snapshot: score ${latestCredit.score ?? "?"} on ${latestCredit.snapshotDate}`);
  }

  return {
    systemPrompt: lines.join("\n"),
    facts: {
      monthlyIncome: summary.totalMonthlyIncome,
      monthlyBills: summary.totalMonthlyBills,
      monthlyDebtMin: summary.totalDebtMinimums,
      monthlySubs: summary.totalMonthlySubscriptions,
      netMonthly: summary.leftoverAfterSavings,
      activeGoals: savingsGoals.length,
      stabilityIndex: stability,
      stabilityLabel: label,
    },
  };
}
