import type { BudgetSummary } from "./budget.types";

/**
 * Returns a single 0-100 health score for the household budget.
 *
 * Components (each capped):
 *   - margin            (leftoverAfterSavings / income)         range -50 .. +30
 *   - savings rate       (savingsRate, capped at 20%)            range   0 .. +20
 *   - bill/debt pressure (penalty above 70% of income)           range -30 ..   0
 *   - actual overspend   (penalty above 90% of income spent MTD) range -10 ..   0
 * Baseline 60 keeps the typical household near the middle of the band.
 *
 * Special cases:
 *   - zero income → 50 (unknowable; do not pretend to know)
 *   - undefined inputs → clamped to 0–100
 */
export function calculateStabilityIndex(summary: BudgetSummary): number {
  const income = summary.totalMonthlyIncome;
  if (income <= 0) return 50;

  const marginRatio = summary.leftoverAfterSavings / income;
  const marginScore = clamp(marginRatio, -0.5, 0.3) * 100; // -50 .. +30

  const savingsScore = Math.min(summary.savingsRate, 0.2) * 100; // 0 .. +20

  const pressurePenalty = -Math.max(0, summary.payPathPressureRatio - 0.7) * 100; // 0 .. -30 (bounded by usage)
  const pressureScore = Math.max(pressurePenalty, -30);

  const actualSpendRatio = summary.actualSpend / income;
  const overspendPenalty = -Math.max(0, actualSpendRatio - 0.9) * 100;
  const overspendScore = Math.max(overspendPenalty, -10);

  const raw = 60 + marginScore + savingsScore + pressureScore + overspendScore;
  return Math.round(clamp(raw, 0, 100));
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

/** Bucket for color/label UX. */
export function stabilityBand(index: number): "critical" | "stressed" | "stable" | "strong" {
  if (index < 30) return "critical";
  if (index < 55) return "stressed";
  if (index < 80) return "stable";
  return "strong";
}
