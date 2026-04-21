import { addMonths, differenceInMonths, isValid, parseISO } from "date-fns";

export interface StashMapForecast {
  isFullyFunded: boolean;
  monthsRemaining: number;
  projectedDate: Date | null;
  status: "ON_TRACK" | "UNDERFUNDED" | "UNKNOWN" | "FUNDED";
  requiredMonthlyToHitDeadline: number | null;
}

export function forecastSavingsGoal(
  targetAmount: number,
  currentAmount: number,
  monthlyContribution: number,
  deadlineIsoString?: string | null
): StashMapForecast {
  const isFullyFunded = currentAmount >= targetAmount;

  if (isFullyFunded) {
    return {
      isFullyFunded: true,
      monthsRemaining: 0,
      projectedDate: new Date(),
      status: "FUNDED",
      requiredMonthlyToHitDeadline: 0,
    };
  }

  const remainingAmount = Math.max(0, targetAmount - currentAmount);
  
  // Calculate raw projection regardless of deadline
  let monthsRemaining = Infinity;
  let projectedDate: Date | null = null;
  
  if (monthlyContribution > 0) {
    monthsRemaining = Math.ceil(remainingAmount / monthlyContribution);
    projectedDate = addMonths(new Date(), monthsRemaining);
  }

  // Calculate status against deadline
  let status: "ON_TRACK" | "UNDERFUNDED" | "UNKNOWN" | "FUNDED" = monthlyContribution > 0 ? "ON_TRACK" : "UNKNOWN";
  let requiredMonthlyToHitDeadline: number | null = null;

  if (deadlineIsoString) {
    const deadlineDate = parseISO(deadlineIsoString);
    if (isValid(deadlineDate)) {
      const monthsToDeadline = differenceInMonths(deadlineDate, new Date());
      
      // If deadline is in the past or this month
      if (monthsToDeadline <= 0) {
        status = "UNDERFUNDED";
        requiredMonthlyToHitDeadline = remainingAmount;
      } else {
        requiredMonthlyToHitDeadline = remainingAmount / monthsToDeadline;
        if (monthlyContribution < requiredMonthlyToHitDeadline) {
          status = "UNDERFUNDED";
        } else {
          status = "ON_TRACK";
        }
      }
    }
  }

  return {
    isFullyFunded: false,
    monthsRemaining: monthsRemaining === Infinity ? 999 : monthsRemaining,
    projectedDate,
    status,
    requiredMonthlyToHitDeadline,
  };
}
