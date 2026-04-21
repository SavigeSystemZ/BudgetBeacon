import { z } from "zod";
import { isoDateStringSchema } from "../../lib/validation/date";

export const frequencySchema = z.enum([
  "weekly",
  "biweekly",
  "semimonthly",
  "monthly",
  "annual",
  "custom",
]);

export type Frequency = z.infer<typeof frequencySchema>;

export const incomeSourceSchema = z.object({
  id: z.string().uuid(),
  householdId: z.string().uuid(),
  personId: z.string().uuid().optional(),
  label: z.string().min(1, "Income label is required"),
  amount: z.number().min(0, "Amount must be zero or greater"),
  frequency: frequencySchema,
  customMonthlyAmount: z.number().min(0).optional(),
  nextPayDate: isoDateStringSchema.optional(),
  isActive: z.boolean(),
  notes: z.string().optional(),
  createdAt: isoDateStringSchema,
  updatedAt: isoDateStringSchema,
});

export type IncomeSource = z.infer<typeof incomeSourceSchema>;
