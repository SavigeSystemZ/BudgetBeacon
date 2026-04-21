export interface BudgetSummary {
  totalMonthlyIncome: number;
  totalMonthlyBills: number;
  totalDebtMinimums: number;
  totalPayPathRequired: number;
  totalStashMapScheduled: number;
  requiredOutflow: number;
  leftoverAfterRequired: number;
  leftoverAfterSavings: number;
  savingsRate: number;
  billPressureRatio: number;
  debtMinimumRatio: number;
  payPathPressureRatio: number;
  budgetStatus: "GREEN" | "YELLOW" | "RED";
  recommendations: string[];
  generatedAt: string;
}
