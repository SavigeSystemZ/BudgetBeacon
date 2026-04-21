import { z } from "zod";
import { isoDateStringSchema } from "../../lib/validation/date";

export const creditSnapshotSchema = z.object({
  id: z.string().uuid(),
  householdId: z.string().uuid(),
  personId: z.string().uuid().optional(),
  score: z.number().min(300, "Score is usually at least 300").max(850, "Score is usually capped at 850"),
  bureauOrSource: z.string().min(1, "Bureau or source is required (e.g., Experian, FICO)"),
  model: z.string().optional(), // e.g., FICO 8, VantageScore 3.0
  snapshotDate: isoDateStringSchema,
  notes: z.string().optional(),
  createdAt: isoDateStringSchema,
  updatedAt: isoDateStringSchema,
});

export type CreditSnapshot = z.infer<typeof creditSnapshotSchema>;
