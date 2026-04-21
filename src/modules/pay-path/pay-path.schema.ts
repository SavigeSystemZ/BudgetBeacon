import { z } from "zod";
import { isoDateStringSchema } from "../../lib/validation/date";
import { frequencySchema } from "../income/income.schema";

export const billCategorySchema = z.enum([
  "housing",
  "utilities",
  "food",
  "transportation",
  "insurance",
  "subscriptions",
  "medical",
  "other",
]);

export type BillCategory = z.infer<typeof billCategorySchema>;

export const billSchema = z.object({
  id: z.string().uuid(),
  householdId: z.string().uuid(),
  label: z.string().min(1, "Bill label is required"),
  category: billCategorySchema,
  amount: z.number().min(0, "Amount must be zero or greater"),
  frequency: frequencySchema,
  customMonthlyAmount: z.number().min(0).optional(),
  dueDay: z.number().min(1).max(31).optional(),
  autopay: z.boolean().default(false),
  isEssential: z.boolean().default(true),
  ownerPersonId: z.string().uuid().optional(),
  notes: z.string().optional(),
  createdAt: isoDateStringSchema,
  updatedAt: isoDateStringSchema,
});

export type Bill = z.infer<typeof billSchema>;

export const debtCategorySchema = z.enum([
  "credit-card",
  "loan",
  "medical",
  "auto",
  "student",
  "personal",
  "other",
]);

export type DebtCategory = z.infer<typeof debtCategorySchema>;

export const debtPrioritySchema = z.enum(["low", "medium", "high"]);

export type DebtPriority = z.infer<typeof debtPrioritySchema>;

export const debtSchema = z.object({
  id: z.string().uuid(),
  householdId: z.string().uuid(),
  label: z.string().min(1, "Debt label is required"),
  creditor: z.string().optional(),
  balance: z.number().min(0, "Balance must be zero or greater"),
  apr: z.number().min(0).optional(),
  minimumPayment: z.number().min(0, "Minimum payment must be zero or greater"),
  dueDay: z.number().min(1).max(31).optional(),
  category: debtCategorySchema,
  ownerPersonId: z.string().uuid().optional(),
  priority: debtPrioritySchema,
  notes: z.string().optional(),
  createdAt: isoDateStringSchema,
  updatedAt: isoDateStringSchema,
});

export type Debt = z.infer<typeof debtSchema>;
