import { z } from "zod";

export const transactionTypeSchema = z.enum(["expense", "income"]);
export type TransactionType = z.infer<typeof transactionTypeSchema>;

export const transactionSchema = z.object({
  id: z.string().uuid(),
  householdId: z.string().uuid(),
  amount: z.number().positive(),
  date: z.string().datetime(), // ISO 8601 string
  payee: z.string().min(1, "Payee is required").max(100),
  category: z.string().min(1, "Category is required"),
  type: transactionTypeSchema,
  notes: z.string().optional(),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
});

export type Transaction = z.infer<typeof transactionSchema>;
