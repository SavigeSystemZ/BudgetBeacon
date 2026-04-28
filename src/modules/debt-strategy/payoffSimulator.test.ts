import { describe, it, expect } from "vitest";
import { simulatePayoff, compareStrategies } from "./payoffSimulator";
import type { SimDebt } from "./payoffSimulator";

const debt = (id: string, balance: number, min: number, apr: number, label = id): SimDebt => ({
  id,
  label,
  balance,
  minimumPayment: min,
  interestRate: apr,
});

describe("M8 — Debt payoff simulator", () => {
  it("pays off a single zero-interest debt at exactly balance/minimum months", () => {
    const r = simulatePayoff([debt("a", 1000, 100, 0)], 0, "minimum");
    expect(r.months).toBe(10);
    expect(r.totalInterestPaid).toBeCloseTo(0, 5);
    expect(r.perDebt[0].payoffMonth).toBe(10);
    expect(r.infeasible).toBe(false);
  });

  it("avalanche targets highest APR first", () => {
    const debts = [
      debt("low", 5000, 100, 5, "Low APR"),
      debt("high", 5000, 100, 25, "High APR"),
    ];
    const r = simulatePayoff(debts, 500, "avalanche");
    const high = r.perDebt.find((d) => d.id === "high")!;
    const low = r.perDebt.find((d) => d.id === "low")!;
    expect(high.payoffMonth).not.toBeNull();
    expect(low.payoffMonth).not.toBeNull();
    expect(high.payoffMonth!).toBeLessThan(low.payoffMonth!);
  });

  it("snowball targets smallest balance first", () => {
    const debts = [
      debt("big", 5000, 100, 25, "Big balance, high APR"),
      debt("small", 500, 50, 5, "Small balance, low APR"),
    ];
    const r = simulatePayoff(debts, 500, "snowball");
    const small = r.perDebt.find((d) => d.id === "small")!;
    const big = r.perDebt.find((d) => d.id === "big")!;
    expect(small.payoffMonth).not.toBeNull();
    expect(big.payoffMonth).not.toBeNull();
    expect(small.payoffMonth!).toBeLessThan(big.payoffMonth!);
  });

  it("avalanche pays less total interest than snowball when APRs diverge", () => {
    const debts = [
      debt("a", 3000, 50, 8, "Smaller balance, lower APR"),
      debt("b", 8000, 100, 24, "Larger balance, higher APR"),
    ];
    const av = simulatePayoff(debts, 300, "avalanche");
    const sn = simulatePayoff(debts, 300, "snowball");
    expect(av.totalInterestPaid).toBeLessThan(sn.totalInterestPaid);
  });

  it("flags infeasible when minimums cannot cover interest and no extra is supplied", () => {
    // 30 % APR on $10k = $250 interest/month; minimum of $100 doesn't cover it.
    const r = simulatePayoff([debt("doom", 10_000, 100, 30)], 0, "minimum");
    expect(r.infeasible).toBe(true);
  });

  it("compareStrategies returns three results with the same total starting balance", () => {
    const debts = [debt("a", 1000, 50, 10), debt("b", 2000, 100, 20)];
    const c = compareStrategies(debts, 200);
    expect(c.avalanche.perDebt.reduce((a, d) => a + d.startingBalance, 0)).toBe(3000);
    expect(c.snowball.perDebt.reduce((a, d) => a + d.startingBalance, 0)).toBe(3000);
    expect(c.minimum.perDebt.reduce((a, d) => a + d.startingBalance, 0)).toBe(3000);
  });

  it("ignores debts with zero balance", () => {
    const debts = [debt("a", 0, 50, 20), debt("b", 1000, 100, 0)];
    const r = simulatePayoff(debts, 0, "minimum");
    expect(r.perDebt).toHaveLength(1);
    expect(r.perDebt[0].id).toBe("b");
    expect(r.months).toBe(10);
  });

  it("trajectory is monotone non-increasing", () => {
    const r = simulatePayoff([debt("a", 5000, 100, 10), debt("b", 2000, 50, 5)], 100, "avalanche");
    for (let i = 1; i < r.trajectory.length; i++) {
      expect(r.trajectory[i].totalBalance).toBeLessThanOrEqual(r.trajectory[i - 1].totalBalance + 0.001);
    }
  });
});
