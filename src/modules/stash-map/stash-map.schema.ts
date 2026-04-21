import { z } from "zod";
import { isoDateStringSchema } from "../../lib/validation/date";

export const stashMapCategorySchema = z.enum([
  "emergency",
  "vehicle",
  "home",
  "vacation",
  "debt-payoff",
  "holiday",
  "other",
]);

export type StashMapCategory = z.infer<typeof stashMapCategorySchema>;
export const stashMapPrioritySchema = z.enum(["low", "medium", "high"]);
export type StashMapPriority = z.infer<typeof stashMapPrioritySchema>;

export const savingsGoalSchema = z.object({
  id: z.string().uuid(),
  householdId: z.string().uuid(),
  label: z.string().min(1, "Savings goal label is required"),
  targetAmount: z.number().min(0.01, "Target amount must be greater than zero"),
  currentAmount: z.number().min(0, "Current amount must be zero or greater"),
  monthlyContribution: z.number().min(0, "Monthly contribution must be zero or greater"),
  deadline: isoDateStringSchema.optional(),
  priority: stashMapPrioritySchema,
  category: stashMapCategorySchema,
  notes: z.string().optional(),
  createdAt: isoDateStringSchema,
  updatedAt: isoDateStringSchema,
});

export type SavingsGoal = z.infer<typeof savingsGoalSchema>;
