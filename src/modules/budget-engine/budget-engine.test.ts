import { describe, it, expect } from "vitest";
import { toMonthlyEquivalent } from "./frequency";
import { calculateBudgetSummary } from "./calculateBudgetSummary";
import type { IncomeSource } from "../income/income.schema";
import type { Bill, Debt } from "../pay-path/pay-path.schema";
import type { SavingsGoal } from "../stash-map/stash-map.schema";

describe("Frequency Normalization", () => {
  it("normalizes weekly", () => expect(toMonthlyEquivalent(100, "weekly")).toBe((100 * 52) / 12));
  it("normalizes biweekly", () => expect(toMonthlyEquivalent(100, "biweekly")).toBe((100 * 26) / 12));
  it("normalizes semimonthly", () => expect(toMonthlyEquivalent(100, "semimonthly")).toBe(200));
  it("normalizes monthly", () => expect(toMonthlyEquivalent(100, "monthly")).toBe(100));
  it("normalizes annual", () => expect(toMonthlyEquivalent(1200, "annual")).toBe(100));
  it("normalizes custom", () => expect(toMonthlyEquivalent(100, "custom", 50)).toBe(50));
  it("handles negative amounts safely", () => expect(toMonthlyEquivalent(-50, "monthly")).toBe(0));
});

describe("calculateBudgetSummary", () => {
  const dummyIncomes: IncomeSource[] = [
    { id: "1", householdId: "h1", label: "Job", amount: 4000, frequency: "monthly", isActive: true, createdAt: "", updatedAt: "" }
  ];
  
  const dummyBills: Bill[] = [
    { id: "2", householdId: "h1", label: "Rent", category: "housing", amount: 2000, frequency: "monthly", autopay: false, isEssential: true, createdAt: "", updatedAt: "" }
  ];

  const dummyDebts: Debt[] = [
    { id: "3", householdId: "h1", label: "Card", balance: 1000, minimumPayment: 500, category: "credit-card", priority: "high", createdAt: "", updatedAt: "" }
  ];

  const dummyGoals: SavingsGoal[] = [
    { id: "4", householdId: "h1", label: "Fund", targetAmount: 10000, currentAmount: 0, monthlyContribution: 1000, category: "emergency", priority: "high", createdAt: "", updatedAt: "" }
  ];

  it("calculates green status when there is a surplus", () => {
    const result = calculateBudgetSummary(dummyIncomes, dummyBills, [], []);
    expect(result.totalMonthlyIncome).toBe(4000);
    expect(result.requiredOutflow).toBe(2000);
    expect(result.leftoverAfterRequired).toBe(2000);
    expect(result.budgetStatus).toBe("GREEN");
  });

  it("calculates yellow status when savings overcommit the budget", () => {
    // Leftover after required = 1500 (4000 - 2500)
    // Leftover after savings = 1500 - 2000 = -500
    const overcommittedGoals = [{ ...dummyGoals[0], monthlyContribution: 2000 }];
    const result = calculateBudgetSummary(dummyIncomes, dummyBills, dummyDebts, overcommittedGoals);
    expect(result.leftoverAfterRequired).toBe(1500);
    expect(result.leftoverAfterSavings).toBe(-500);
    expect(result.budgetStatus).toBe("YELLOW");
    expect(result.recommendations).toContain("Stash Map is overcommitted by $500.00/month. Consider reducing scheduled savings until Pay Path is stable.");
  });

  it("calculates red status when required outflow exceeds income", () => {
    const hugeBills = [{ ...dummyBills[0], amount: 5000 }];
    const result = calculateBudgetSummary(dummyIncomes, hugeBills, [], []);
    expect(result.leftoverAfterRequired).toBe(-1000);
    expect(result.budgetStatus).toBe("RED");
    expect(result.recommendations).toContain("Pay Path is short by $1000.00/month before savings.");
  });

  it("handles zero income gracefully", () => {
    const result = calculateBudgetSummary([], [], [], []);
    expect(result.totalMonthlyIncome).toBe(0);
    expect(result.budgetStatus).toBe("GREEN");
    expect(result.recommendations).toContain("Add an active income source to see accurate budget pressure.");
  });

  it("calculates pressure ratios correctly", () => {
    const result = calculateBudgetSummary(dummyIncomes, dummyBills, dummyDebts, []);
    // Income 4000, Bills 2000, Debt 500. Total required = 2500.
    expect(result.billPressureRatio).toBe(2000 / 4000);
    expect(result.debtMinimumRatio).toBe(500 / 4000);
    expect(result.payPathPressureRatio).toBe(2500 / 4000);
  });
});
