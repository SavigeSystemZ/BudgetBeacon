export interface BudgetSummary {
  totalMonthlyIncome: number;
  totalMonthlyBills: number;
  totalDebtMinimums: number;
  totalMonthlySubscriptions: number;
  totalMonthlyInsurance: number;
  totalPayPathRequired: number;
  totalStashMapScheduled: number;
  requiredOutflow: number;
  leftoverAfterRequired: number;
  leftoverAfterSavings: number;
  actualIncome: number;
  actualSpend: number;
  remainingBudget: number;
  savingsRate: number;
  billPressureRatio: number;
  debtMinimumRatio: number;
  subscriptionPressureRatio: number;
  payPathPressureRatio: number;
  budgetStatus: "GREEN" | "YELLOW" | "RED";
  recommendations: string[];
  generatedAt: string;
}
