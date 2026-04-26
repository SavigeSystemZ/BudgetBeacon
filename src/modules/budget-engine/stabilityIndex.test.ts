import { describe, it, expect } from "vitest";
import { calculateStabilityIndex, stabilityBand } from "./stabilityIndex";
import type { BudgetSummary } from "./budget.types";

function makeSummary(overrides: Partial<BudgetSummary>): BudgetSummary {
  return {
    totalMonthlyIncome: 4000,
    totalMonthlyBills: 2000,
    totalDebtMinimums: 0,
    totalMonthlySubscriptions: 0,
    totalMonthlyInsurance: 0,
    totalPayPathRequired: 2000,
    totalStashMapScheduled: 500,
    requiredOutflow: 2000,
    leftoverAfterRequired: 2000,
    leftoverAfterSavings: 1500,
    actualIncome: 0,
    actualSpend: 0,
    remainingBudget: 1500,
    savingsRate: 500 / 4000,
    billPressureRatio: 2000 / 4000,
    debtMinimumRatio: 0,
    subscriptionPressureRatio: 0,
    payPathPressureRatio: 2000 / 4000,
    budgetStatus: "GREEN",
    recommendations: [],
    generatedAt: new Date().toISOString(),
    ...overrides,
  };
}

describe("calculateStabilityIndex", () => {
  it("returns 50 for zero income (unknowable)", () => {
    const result = calculateStabilityIndex(makeSummary({ totalMonthlyIncome: 0 }));
    expect(result).toBe(50);
  });

  it("rewards healthy margin + savings", () => {
    // income 4000, leftoverAfterSavings 1500, savingsRate 12.5%, pressure 50%
    const result = calculateStabilityIndex(makeSummary({}));
    // margin 0.375 → clamped to 0.3 → +30
    // savings 0.125 → +12.5
    // pressure 50% (< 70%) → 0
    // overspend 0 → 0
    // baseline 60 + 30 + 12.5 = 102.5 → clamped 100
    expect(result).toBe(100);
  });

  it("penalises high pay-path pressure", () => {
    // require 3700/4000 = 92.5% pressure → -22.5
    const result = calculateStabilityIndex(
      makeSummary({
        totalMonthlyBills: 3700,
        totalPayPathRequired: 3700,
        requiredOutflow: 3700,
        leftoverAfterRequired: 300,
        leftoverAfterSavings: -200,
        billPressureRatio: 3700 / 4000,
        payPathPressureRatio: 3700 / 4000,
      })
    );
    expect(result).toBeLessThan(50);
    expect(result).toBeGreaterThanOrEqual(0);
  });

  it("returns low score in clear deficit", () => {
    const result = calculateStabilityIndex(
      makeSummary({
        totalMonthlyBills: 4500,
        totalPayPathRequired: 4500,
        requiredOutflow: 4500,
        leftoverAfterRequired: -500,
        leftoverAfterSavings: -1000,
        billPressureRatio: 4500 / 4000,
        payPathPressureRatio: 4500 / 4000,
        budgetStatus: "RED",
      })
    );
    expect(result).toBeLessThan(30);
  });

  it("penalises actual overspend MTD", () => {
    const baseline = calculateStabilityIndex(makeSummary({}));
    const overspent = calculateStabilityIndex(makeSummary({ actualSpend: 4200 })); // 105% of income spent
    expect(overspent).toBeLessThan(baseline);
  });

  it("stays within [0, 100]", () => {
    const high = calculateStabilityIndex(
      makeSummary({ leftoverAfterSavings: 100000, savingsRate: 1 })
    );
    const low = calculateStabilityIndex(
      makeSummary({ leftoverAfterSavings: -100000, payPathPressureRatio: 5, actualSpend: 99999 })
    );
    expect(high).toBeLessThanOrEqual(100);
    expect(low).toBeGreaterThanOrEqual(0);
  });
});

describe("stabilityBand", () => {
  it("buckets correctly", () => {
    expect(stabilityBand(10)).toBe("critical");
    expect(stabilityBand(40)).toBe("stressed");
    expect(stabilityBand(70)).toBe("stable");
    expect(stabilityBand(95)).toBe("strong");
  });
});
