import type { IncomeSource } from "../income/income.schema";
import type { Bill, Debt } from "../pay-path/pay-path.schema";
import type { SavingsGoal } from "../stash-map/stash-map.schema";
import type { Transaction } from "../ledger/ledger.schema";
import { toMonthlyEquivalent } from "./frequency";
import type { BudgetSummary } from "./budget.types";
import { generateRecommendations } from "./recommendations";

export function calculateBudgetSummary(
  incomes: IncomeSource[],
  bills: Bill[],
  debts: Debt[],
  savingsGoals: SavingsGoal[],
  transactions: Transaction[] = [],
  subscriptions: { amount: number; frequency: string }[] = [],
  insurance: { premium?: number }[] = []
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

  // 3. Debts
  const totalDebtMinimums = debts.reduce((sum, debt) => sum + Math.max(0, debt.minimumPayment), 0);

  // 4. Subscriptions
  const totalMonthlySubscriptions = subscriptions.reduce((sum, sub) => {
    const amt = sub.amount || 0;
    if (sub.frequency === "annual") return sum + (amt / 12);
    if (sub.frequency === "quarterly") return sum + (amt / 3);
    return sum + amt;
  }, 0);

  // 5. Insurance
  const totalMonthlyInsurance = insurance.reduce((sum, ins) => sum + (ins.premium || 0), 0);

  // 6. Savings
  const totalStashMapScheduled = savingsGoals.reduce((sum, goal) => sum + Math.max(0, goal.monthlyContribution), 0);

  // 7. Actuals (Current Month)
  const currentMonth = new Date().toISOString().slice(0, 7); 
  const currentMonthTransactions = transactions.filter(t => t.date.startsWith(currentMonth));
  
  const actualIncome = currentMonthTransactions
    .filter(t => t.type === "income")
    .reduce((sum, t) => sum + t.amount, 0);
    
  const actualSpend = currentMonthTransactions
    .filter(t => t.type === "expense")
    .reduce((sum, t) => sum + t.amount, 0);

  // 8. Aggregations
  const totalPayPathRequired = totalMonthlyBills + totalDebtMinimums + totalMonthlySubscriptions + totalMonthlyInsurance;
  const requiredOutflow = totalPayPathRequired;
  const leftoverAfterRequired = totalMonthlyIncome - requiredOutflow;
  const leftoverAfterSavings = leftoverAfterRequired - totalStashMapScheduled;
  const remainingBudget = totalMonthlyIncome - actualSpend - totalStashMapScheduled; 

  // 9. Ratios
  const billPressureRatio = totalMonthlyIncome > 0 ? totalMonthlyBills / totalMonthlyIncome : 0;
  const debtMinimumRatio = totalMonthlyIncome > 0 ? totalDebtMinimums / totalMonthlyIncome : 0;
  const subscriptionPressureRatio = totalMonthlyIncome > 0 ? totalMonthlySubscriptions / totalMonthlyIncome : 0;
  const payPathPressureRatio = totalMonthlyIncome > 0 ? requiredOutflow / totalMonthlyIncome : 0;
  const savingsRate = totalMonthlyIncome > 0 ? totalStashMapScheduled / totalMonthlyIncome : 0;

  // 10. Status Logic
  let budgetStatus: "GREEN" | "YELLOW" | "RED" = "GREEN";
  if (remainingBudget < 0 || leftoverAfterRequired < 0) {
    budgetStatus = "RED";
  } else if (leftoverAfterSavings < 0 || payPathPressureRatio > 0.85 || actualSpend > (totalMonthlyIncome * 0.9)) {
    budgetStatus = "YELLOW";
  }

  // 11. Recommendations
  const partialSummary = {
    totalMonthlyIncome,
    totalMonthlyBills,
    totalDebtMinimums,
    totalMonthlySubscriptions,
    totalMonthlyInsurance,
    totalPayPathRequired,
    totalStashMapScheduled,
    requiredOutflow,
    leftoverAfterRequired,
    leftoverAfterSavings,
    actualIncome,
    actualSpend,
    remainingBudget,
    savingsRate,
    billPressureRatio,
    debtMinimumRatio,
    subscriptionPressureRatio,
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
