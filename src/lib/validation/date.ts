import { z } from "zod";

// Ensures dates are stored in a standard ISO format (e.g., YYYY-MM-DD or YYYY-MM-DDTHH:mm:ss.sssZ)
export const isoDateStringSchema = z
  .string()
  .refine((val) => !isNaN(Date.parse(val)), {
    message: "Invalid date format. Must be an ISO date string.",
  });

export type ISODateString = z.infer<typeof isoDateStringSchema>;
