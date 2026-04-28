import { db } from "../../db/db";
import { createId } from "../../lib/ids/createId";
import type { ProposedAction } from "./types";

export interface ApplyContext {
  householdId: string;
  personId: string;
}

/**
 * Commit a single approved action to Dexie. Returns a short audit string that
 * the UI can append to the chat as a confirmation receipt.
 *
 * Throws on missing household — the chatbot should surface that error rather
 * than silently dropping the write.
 */
export async function applyProposedAction(action: ProposedAction, ctx: ApplyContext): Promise<string> {
  if (!ctx.householdId) throw new Error("No active household. Open Settings to initialize.");
  const now = new Date().toISOString();

  if (action.type === "addIncome") {
    const id = createId();
    await db.incomeSources.add({
      id,
      householdId: ctx.householdId,
      personId: ctx.personId,
      label: action.label,
      amount: action.amount,
      frequency: action.frequency,
      isActive: true,
      notes: "Added via Beacon Agent (user approved)",
      createdAt: now,
      updatedAt: now,
    });
    return `Added income "${action.label}" — $${action.amount} ${action.frequency}.`;
  }

  if (action.type === "addBill") {
    const id = createId();
    await db.bills.add({
      id,
      householdId: ctx.householdId,
      ownerPersonId: ctx.personId,
      label: action.label,
      category: (action.category as "housing" | "utilities" | "food" | "transportation" | "insurance" | "subscriptions" | "medical" | "other") || "other",
      amount: action.amount,
      frequency: action.frequency,
      dueDay: action.dueDay ?? 15,
      autopay: false,
      isEssential: false,
      notes: "Added via Beacon Agent (user approved)",
      createdAt: now,
      updatedAt: now,
    });
    return `Added bill "${action.label}" — $${action.amount} ${action.frequency}.`;
  }

  if (action.type === "addSavingsGoal") {
    const id = createId();
    await db.savingsGoals.add({
      id,
      householdId: ctx.householdId,
      label: action.label,
      category: action.category || "other",
      priority: action.priority || "medium",
      targetAmount: action.targetAmount,
      currentAmount: 0,
      monthlyContribution: action.monthlyContribution,
      notes: "Added via Beacon Agent (user approved)",
      createdAt: now,
      updatedAt: now,
    });
    return `Added savings goal "${action.label}" — target $${action.targetAmount}.`;
  }

  // Exhaustive — TS will complain if a new action type is added without a handler.
  const _exhaustive: never = action;
  return _exhaustive;
}

/** Human-readable summary for a confirmation chip. */
export function describeAction(action: ProposedAction): string {
  switch (action.type) {
    case "addIncome":
      return `Add income "${action.label}" — $${action.amount.toLocaleString()} ${action.frequency}`;
    case "addBill":
      return `Add bill "${action.label}" — $${action.amount.toLocaleString()} ${action.frequency}${action.dueDay ? ` (due day ${action.dueDay})` : ""}`;
    case "addSavingsGoal":
      return `Add savings goal "${action.label}" — target $${action.targetAmount.toLocaleString()}, $${action.monthlyContribution.toLocaleString()}/mo`;
  }
}
