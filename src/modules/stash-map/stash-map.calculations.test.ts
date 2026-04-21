import { describe, it, expect } from "vitest";
import { forecastSavingsGoal } from "./stash-map.calculations";
import { addMonths } from "date-fns";

describe("forecastSavingsGoal", () => {
  it("returns FUNDED when target is reached", () => {
    const result = forecastSavingsGoal(1000, 1000, 100);
    expect(result.isFullyFunded).toBe(true);
    expect(result.status).toBe("FUNDED");
    expect(result.monthsRemaining).toBe(0);
  });

  it("calculates months remaining accurately", () => {
    // Needs 500. Contributes 100/mo. -> 5 months.
    const result = forecastSavingsGoal(1000, 500, 100);
    expect(result.isFullyFunded).toBe(false);
    expect(result.monthsRemaining).toBe(5);
    expect(result.status).toBe("ON_TRACK"); // Assumes on-track if no deadline
  });

  it("handles zero contribution", () => {
    const result = forecastSavingsGoal(1000, 500, 0);
    expect(result.isFullyFunded).toBe(false);
    expect(result.monthsRemaining).toBe(999);
    expect(result.projectedDate).toBe(null);
    expect(result.status).toBe("UNKNOWN");
  });

  it("calculates UNDERFUNDED when deadline is impossible with current contribution", () => {
    const deadline = addMonths(new Date(), 2).toISOString();
    // Needs 1000 in 2 months. Required: 500/mo. Actual: 100/mo.
    const result = forecastSavingsGoal(1000, 0, 100, deadline);
    expect(result.status).toBe("UNDERFUNDED");
    expect(result.requiredMonthlyToHitDeadline).toBeGreaterThan(400); 
    // Usually close to 500, depends on exact date-fns diff
  });

  it("calculates ON_TRACK when deadline is possible", () => {
    const deadline = addMonths(new Date(), 10).toISOString();
    // Needs 1000 in 10 months. Required: 100/mo. Actual: 150/mo.
    const result = forecastSavingsGoal(1000, 0, 150, deadline);
    expect(result.status).toBe("ON_TRACK");
    expect(result.requiredMonthlyToHitDeadline).toBeLessThanOrEqual(150);
  });
});
