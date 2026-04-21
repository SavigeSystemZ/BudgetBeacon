import type { Frequency } from "../income/income.schema";

export function toMonthlyEquivalent(
  amount: number,
  frequency: Frequency,
  customMonthlyAmount?: number
): number {
  if (amount < 0) return 0;

  switch (frequency) {
    case "weekly":
      return (amount * 52) / 12;
    case "biweekly":
      return (amount * 26) / 12;
    case "semimonthly":
      return amount * 2;
    case "monthly":
      return amount;
    case "annual":
      return amount / 12;
    case "custom":
      return customMonthlyAmount && customMonthlyAmount >= 0 ? customMonthlyAmount : 0;
    default:
      return 0;
  }
}
