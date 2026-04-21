import type { IncomeSource } from "../income/income.schema";
import type { Bill, Debt } from "../pay-path/pay-path.schema";
import type { SavingsGoal } from "../stash-map/stash-map.schema";
import { toMonthlyEquivalent } from "./frequency";
import type { BudgetSummary } from "./budget.types";
import { generateRecommendations } from "./recommendations";

export function calculateBudgetSummary(
  incomes: IncomeSource[],
  bills: Bill[],
  debts: Debt[],
  savingsGoals: SavingsGoal[]
): BudgetSummary {
  // 1. Incomes
  const totalMonthlyIncome = incomes
    .filter((inc) => inc.isActive)
    .reduce((sum, inc) => sum + toMonthlyEquivalent(inc.amount, inc.frequency, inc.customMonthlyAmount), 0);

  // 2. Bills
  const totalMonthlyBills = bills.reduce(
    (sum, bill) => sum + toMonthlyEquivalent(bill.amount, bill.frequency, bill.customMonthlyAmount),
    0
  );

  // 3. Debts (Debts are assumed to be tracked with monthly minimums by default per schema, 
  // but if we used a frequency enum we'd normalize here. NFR says "minimumPayment" represents the required monthly).
  const totalDebtMinimums = debts.reduce((sum, debt) => sum + Math.max(0, debt.minimumPayment), 0);

  // 4. Savings
  const totalStashMapScheduled = savingsGoals.reduce((sum, goal) => sum + Math.max(0, goal.monthlyContribution), 0);

  // 5. Aggregations
  const totalPayPathRequired = totalMonthlyBills + totalDebtMinimums;
  const requiredOutflow = totalPayPathRequired;
  const leftoverAfterRequired = totalMonthlyIncome - requiredOutflow;
  const leftoverAfterSavings = leftoverAfterRequired - totalStashMapScheduled;

  // 6. Ratios
  const billPressureRatio = totalMonthlyIncome > 0 ? totalMonthlyBills / totalMonthlyIncome : 0;
  const debtMinimumRatio = totalMonthlyIncome > 0 ? totalDebtMinimums / totalMonthlyIncome : 0;
  const payPathPressureRatio = totalMonthlyIncome > 0 ? requiredOutflow / totalMonthlyIncome : 0;
  const savingsRate = totalMonthlyIncome > 0 ? totalStashMapScheduled / totalMonthlyIncome : 0;

  // 7. Status Logic
  let budgetStatus: "GREEN" | "YELLOW" | "RED" = "GREEN";
  if (leftoverAfterRequired < 0) {
    budgetStatus = "RED";
  } else if (leftoverAfterSavings < 0 || payPathPressureRatio > 0.85) {
    budgetStatus = "YELLOW";
  }

  // 8. Recommendations
  const partialSummary = {
    totalMonthlyIncome,
    totalMonthlyBills,
    totalDebtMinimums,
    totalPayPathRequired,
    totalStashMapScheduled,
    requiredOutflow,
    leftoverAfterRequired,
    leftoverAfterSavings,
    savingsRate,
    billPressureRatio,
    debtMinimumRatio,
    payPathPressureRatio,
    budgetStatus,
  };

  const recommendations = generateRecommendations(partialSummary);

  return {
    ...partialSummary,
    recommendations,
    generatedAt: new Date().toISOString(),
  };
}
