/**
 * Debt payoff simulation. Pure, deterministic, monthly-step.
 *
 * Strategies:
 *   - "avalanche" — pay extra toward highest-APR first (mathematically optimal)
 *   - "snowball"  — pay extra toward smallest-balance first (motivational)
 *   - "minimum"   — pay only minimums (baseline / control)
 *
 * Inputs come straight from the existing `debts` rows (balance, minimumPayment,
 * interestRate as percent, e.g. 22.99). Interest accrues monthly = APR / 12.
 *
 * The simulator caps at 600 months (50 years) to avoid runaway loops when the
 * user's combined minimums don't cover the interest. In that case the
 * `infeasible` flag is set and the result still describes the best-effort
 * trajectory.
 */

export interface SimDebt {
  id: string;
  label: string;
  balance: number;
  minimumPayment: number;
  /** Annual percentage rate, e.g. 22.99 for 22.99 %. */
  interestRate: number;
}

export type Strategy = "avalanche" | "snowball" | "minimum";

export interface PayoffResult {
  strategy: Strategy;
  months: number;
  totalInterestPaid: number;
  totalPaid: number;
  perDebt: Array<{
    id: string;
    label: string;
    payoffMonth: number | null; // null when infeasible
    interestPaid: number;
    startingBalance: number;
  }>;
  /** Monthly snapshot of total balance, useful for charts. */
  trajectory: Array<{ month: number; totalBalance: number }>;
  infeasible: boolean;
}

const MAX_MONTHS = 600;

export function simulatePayoff(
  inputs: SimDebt[],
  monthlyExtra: number,
  strategy: Strategy,
): PayoffResult {
  const debts = inputs
    .filter((d) => d.balance > 0)
    .map((d) => ({
      id: d.id,
      label: d.label,
      balance: d.balance,
      minimum: Math.max(0, d.minimumPayment),
      apr: Math.max(0, d.interestRate),
      paid: 0,
      interest: 0,
      payoffMonth: null as number | null,
      startingBalance: d.balance,
    }));

  const trajectory: PayoffResult["trajectory"] = [];
  let infeasible = false;
  let month = 0;

  while (debts.some((d) => d.balance > 0.005) && month < MAX_MONTHS) {
    month += 1;

    // 1. Accrue monthly interest on every debt with a balance.
    let interestThisMonth = 0;
    for (const d of debts) {
      if (d.balance <= 0) continue;
      const monthlyRate = d.apr / 100 / 12;
      const accrued = d.balance * monthlyRate;
      d.balance += accrued;
      d.interest += accrued;
      interestThisMonth += accrued;
    }

    // 2. Pay each debt's minimum, capped at remaining balance.
    let totalMinimumNeeded = 0;
    let minimumApplied = 0;
    for (const d of debts) {
      if (d.balance <= 0) continue;
      totalMinimumNeeded += d.minimum;
      const pay = Math.min(d.minimum, d.balance);
      d.balance -= pay;
      d.paid += pay;
      minimumApplied += pay;
    }

    // Did the minimums even cover the accrued interest? If not, this strategy
    // is infeasible at the current monthlyExtra; we keep simulating but flag it.
    if (strategy !== "minimum" && minimumApplied + monthlyExtra < interestThisMonth - 0.01) {
      infeasible = true;
    }
    if (strategy === "minimum" && minimumApplied < interestThisMonth - 0.01) {
      infeasible = true;
    }

    // 3. Apply extra payment per strategy.
    let extra = strategy === "minimum" ? 0 : monthlyExtra;
    while (extra > 0.005) {
      const target = pickTarget(debts, strategy);
      if (!target) break;
      const pay = Math.min(extra, target.balance);
      target.balance -= pay;
      target.paid += pay;
      extra -= pay;
    }

    // 4. Record any debts that crossed zero this month.
    for (const d of debts) {
      if (d.balance <= 0.005 && d.payoffMonth === null) {
        d.payoffMonth = month;
        d.balance = 0;
      }
    }

    const totalBalance = debts.reduce((acc, d) => acc + d.balance, 0);
    trajectory.push({ month, totalBalance });
  }

  if (debts.some((d) => d.balance > 0.005)) infeasible = true;
  if (totalMinimumOf(inputs) === 0 && monthlyExtra <= 0) infeasible = true;

  const totalInterestPaid = debts.reduce((acc, d) => acc + d.interest, 0);
  const totalPaid = debts.reduce((acc, d) => acc + d.paid, 0);

  return {
    strategy,
    months: month,
    totalInterestPaid,
    totalPaid,
    infeasible,
    perDebt: debts.map((d) => ({
      id: d.id,
      label: d.label,
      payoffMonth: d.payoffMonth,
      interestPaid: d.interest,
      startingBalance: d.startingBalance,
    })),
    trajectory,
  };
}

type SimRow = { balance: number; apr: number; paid: number; startingBalance: number };

function pickTarget(debts: SimRow[], strategy: Strategy): SimRow | undefined {
  const remaining = debts.filter((d) => d.balance > 0.005);
  if (remaining.length === 0) return undefined;
  if (strategy === "avalanche") {
    return remaining.reduce((best, d) => (d.apr > best.apr ? d : best));
  }
  if (strategy === "snowball") {
    return remaining.reduce((best, d) => (d.balance < best.balance ? d : best));
  }
  return undefined;
}

function totalMinimumOf(inputs: SimDebt[]): number {
  return inputs.reduce((acc, d) => acc + (d.balance > 0 ? d.minimumPayment : 0), 0);
}

/** Compare avalanche vs snowball at a given monthly-extra. Returns both results. */
export function compareStrategies(
  inputs: SimDebt[],
  monthlyExtra: number,
): { avalanche: PayoffResult; snowball: PayoffResult; minimum: PayoffResult } {
  return {
    avalanche: simulatePayoff(inputs, monthlyExtra, "avalanche"),
    snowball: simulatePayoff(inputs, monthlyExtra, "snowball"),
    minimum: simulatePayoff(inputs, 0, "minimum"),
  };
}
