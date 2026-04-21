import { z } from "zod";
import { isoDateStringSchema } from "../../lib/validation/date";

export const householdSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1, "Household name is required"),
  currency: z.string().default("USD"),
  createdAt: isoDateStringSchema,
  updatedAt: isoDateStringSchema,
});

export type Household = z.infer<typeof householdSchema>;

export const personSchema = z.object({
  id: z.string().uuid(),
  householdId: z.string().uuid(),
  name: z.string().min(1, "Name is required"),
  role: z.enum(["primary", "partner", "other"]),
  colorTag: z.string().optional(),
  createdAt: isoDateStringSchema,
  updatedAt: isoDateStringSchema,
});

export type Person = z.infer<typeof personSchema>;
