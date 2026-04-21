import type { BudgetSummary } from "./budget.types";

export function generateRecommendations(summary: Omit<BudgetSummary, "recommendations" | "generatedAt">): string[] {
  const recs: string[] = [];

  // Pay Path checks
  if (summary.leftoverAfterRequired < 0) {
    recs.push(`Pay Path is short by $${Math.abs(summary.leftoverAfterRequired).toFixed(2)}/month before savings.`);
  } else if (summary.payPathPressureRatio > 0.85) {
    recs.push(`Bills and debt consume ${(summary.payPathPressureRatio * 100).toFixed(1)}% of your monthly income. Focus on reducing fixed costs.`);
  } else {
    recs.push(`You have $${summary.leftoverAfterRequired.toFixed(2)}/month available after required bills and minimum debt payments.`);
  }

  // Stash Map checks
  if (summary.leftoverAfterRequired >= 0 && summary.leftoverAfterSavings < 0) {
    recs.push(`Stash Map is overcommitted by $${Math.abs(summary.leftoverAfterSavings).toFixed(2)}/month. Consider reducing scheduled savings until Pay Path is stable.`);
  }

  // Savings rate note
  if (summary.savingsRate > 0 && summary.leftoverAfterSavings >= 0) {
    recs.push(`You are successfully planning to save ${(summary.savingsRate * 100).toFixed(1)}% of your income.`);
  }

  // Missing data safeguards
  if (summary.totalMonthlyIncome === 0) {
    recs.push("Add an active income source to see accurate budget pressure.");
  }

  return recs;
}
