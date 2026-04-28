import { z } from "zod";
import type { ProposedAction } from "./types";

/**
 * The assistant emits zero or more action proposals at the end of its reply,
 * each as a fenced JSON block with the language tag `beacon-action`:
 *
 *   ```beacon-action
 *   { "type": "addIncome", "label": "SSDI", "amount": 1450, "frequency": "monthly" }
 *   ```
 *
 * We parse and validate them with Zod. Anything that doesn't validate is
 * dropped silently — the prose answer is unaffected. Nothing is committed
 * here; the UI surfaces a confirm chip and `applyProposedAction` runs only
 * on explicit click.
 */

const frequencyIncome = z.enum(["weekly", "biweekly", "semimonthly", "monthly", "annual"]);
const frequencyBill = z.enum(["weekly", "biweekly", "monthly", "annual"]);

const addIncomeSchema = z.object({
  type: z.literal("addIncome"),
  label: z.string().min(1).max(100),
  amount: z.number().positive().max(10_000_000),
  frequency: frequencyIncome,
});

const billCategoryEnum = z.enum([
  "housing",
  "utilities",
  "food",
  "transportation",
  "insurance",
  "subscriptions",
  "medical",
  "other",
]);

const stashCategoryEnum = z.enum([
  "emergency",
  "vehicle",
  "home",
  "vacation",
  "debt-payoff",
  "holiday",
  "other",
]);

const stashPriorityEnum = z.enum(["low", "medium", "high"]);

const addBillSchema = z.object({
  type: z.literal("addBill"),
  label: z.string().min(1).max(100),
  amount: z.number().positive().max(10_000_000),
  frequency: frequencyBill,
  category: billCategoryEnum.optional(),
  dueDay: z.number().int().min(1).max(31).optional(),
});

const addSavingsGoalSchema = z.object({
  type: z.literal("addSavingsGoal"),
  label: z.string().min(1).max(100),
  targetAmount: z.number().positive().max(100_000_000),
  monthlyContribution: z.number().nonnegative().max(10_000_000),
  category: stashCategoryEnum.optional(),
  priority: stashPriorityEnum.optional(),
});

const actionSchema = z.discriminatedUnion("type", [addIncomeSchema, addBillSchema, addSavingsGoalSchema]);

const FENCE_RE = /```beacon-action\s*([\s\S]*?)```/g;

export interface ParsedAssistantReply {
  /** Prose with action fences removed. */
  visibleText: string;
  /** Validated proposals — invalid ones are dropped. */
  actions: ProposedAction[];
}

export function parseAssistantReply(raw: string): ParsedAssistantReply {
  const actions: ProposedAction[] = [];
  let m: RegExpExecArray | null;
  FENCE_RE.lastIndex = 0;
  while ((m = FENCE_RE.exec(raw)) !== null) {
    const body = m[1].trim();
    try {
      const obj = JSON.parse(body);
      const parsed = actionSchema.safeParse(obj);
      if (parsed.success) actions.push(parsed.data);
    } catch {
      // ignore malformed fence
    }
  }
  const visibleText = raw.replace(FENCE_RE, "").trim();
  return { visibleText, actions };
}

/** System-prompt fragment teaching the model the action grammar. */
export const ACTION_GRAMMAR_PROMPT = `
When the user asks you to add or change data, do NOT claim you wrote anything.
Instead, propose actions by appending one fenced block per action at the END of your reply, exactly like this (no other JSON in your reply):

\`\`\`beacon-action
{ "type": "addIncome", "label": "SSDI", "amount": 1450, "frequency": "monthly" }
\`\`\`

Allowed action types:
- { "type": "addIncome", "label": string, "amount": number, "frequency": "weekly"|"biweekly"|"semimonthly"|"monthly"|"annual" }
- { "type": "addBill", "label": string, "amount": number, "frequency": "weekly"|"biweekly"|"monthly"|"annual", "category"?: string, "dueDay"?: 1-31 }
- { "type": "addSavingsGoal", "label": string, "targetAmount": number, "monthlyContribution": number, "category"?: string }

Only propose actions when the user clearly asks for them. The user will explicitly approve each proposal before anything is saved. If you have nothing to propose, just answer in prose with no fenced block.
`.trim();
