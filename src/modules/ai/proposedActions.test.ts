import { describe, it, expect, beforeEach } from "vitest";
import { parseAssistantReply } from "./proposedActions";
import { applyProposedAction, describeAction } from "./applyProposedAction";
import { db } from "../../db/db";

describe("M7.2 — proposed action parsing & apply", () => {
  describe("parseAssistantReply", () => {
    it("extracts a single addIncome proposal and strips the fence from visible text", () => {
      const raw =
        "Sure, I can propose that.\n\n```beacon-action\n" +
        '{ "type": "addIncome", "label": "SSDI", "amount": 1450, "frequency": "monthly" }\n' +
        "```";
      const out = parseAssistantReply(raw);
      expect(out.actions).toHaveLength(1);
      expect(out.actions[0]).toMatchObject({ type: "addIncome", label: "SSDI", amount: 1450 });
      expect(out.visibleText).toBe("Sure, I can propose that.");
    });

    it("extracts multiple proposals", () => {
      const raw =
        "Two changes:\n" +
        '```beacon-action\n{ "type": "addBill", "label": "Internet", "amount": 80, "frequency": "monthly" }\n```\n' +
        '```beacon-action\n{ "type": "addSavingsGoal", "label": "Emergency", "targetAmount": 5000, "monthlyContribution": 200 }\n```';
      const out = parseAssistantReply(raw);
      expect(out.actions).toHaveLength(2);
      expect(out.actions[0].type).toBe("addBill");
      expect(out.actions[1].type).toBe("addSavingsGoal");
    });

    it("drops malformed JSON without erroring", () => {
      const raw = "Hi.\n```beacon-action\nnot json\n```";
      const out = parseAssistantReply(raw);
      expect(out.actions).toHaveLength(0);
      expect(out.visibleText).toBe("Hi.");
    });

    it("drops actions that fail schema validation (negative amount)", () => {
      const raw = '```beacon-action\n{"type":"addIncome","label":"X","amount":-5,"frequency":"monthly"}\n```';
      const out = parseAssistantReply(raw);
      expect(out.actions).toHaveLength(0);
    });

    it("drops actions with unknown type", () => {
      const raw = '```beacon-action\n{"type":"deleteEverything","label":"x"}\n```';
      const out = parseAssistantReply(raw);
      expect(out.actions).toHaveLength(0);
    });

    it("returns no actions when there is no fence", () => {
      const out = parseAssistantReply("Just prose, no actions.");
      expect(out.actions).toEqual([]);
      expect(out.visibleText).toBe("Just prose, no actions.");
    });
  });

  describe("applyProposedAction", () => {
    const householdId = "00000000-0000-0000-0000-000000000001";
    const personId = "00000000-0000-0000-0000-000000000002";

    beforeEach(async () => {
      await db.incomeSources.clear();
      await db.bills.clear();
      await db.savingsGoals.clear();
    });

    it("commits an addIncome action", async () => {
      const receipt = await applyProposedAction(
        { type: "addIncome", label: "SSDI", amount: 1450, frequency: "monthly" },
        { householdId, personId },
      );
      expect(receipt).toMatch(/Added income/);
      const all = await db.incomeSources.toArray();
      expect(all).toHaveLength(1);
      expect(all[0].label).toBe("SSDI");
      expect(all[0].amount).toBe(1450);
      expect(all[0].notes).toMatch(/user approved/i);
    });

    it("commits an addBill action with default category and dueDay", async () => {
      await applyProposedAction(
        { type: "addBill", label: "Electric", amount: 120, frequency: "monthly" },
        { householdId, personId },
      );
      const [bill] = await db.bills.toArray();
      expect(bill.label).toBe("Electric");
      expect(bill.category).toBe("other");
      expect(bill.dueDay).toBe(15);
    });

    it("commits an addSavingsGoal action with priority default", async () => {
      await applyProposedAction(
        { type: "addSavingsGoal", label: "Emergency Fund", targetAmount: 5000, monthlyContribution: 200 },
        { householdId, personId },
      );
      const [goal] = await db.savingsGoals.toArray();
      expect(goal.targetAmount).toBe(5000);
      expect((goal as unknown as { priority: string }).priority).toBe("medium");
    });

    it("throws when no household is active", async () => {
      await expect(
        applyProposedAction(
          { type: "addIncome", label: "X", amount: 1, frequency: "monthly" },
          { householdId: "", personId },
        ),
      ).rejects.toThrow(/No active household/);
    });
  });

  describe("describeAction", () => {
    it("formats addIncome", () => {
      expect(
        describeAction({ type: "addIncome", label: "SSDI", amount: 1450, frequency: "monthly" }),
      ).toBe('Add income "SSDI" — $1,450 monthly');
    });
    it("formats addBill with dueDay", () => {
      expect(
        describeAction({ type: "addBill", label: "Rent", amount: 1200, frequency: "monthly", dueDay: 1 }),
      ).toBe('Add bill "Rent" — $1,200 monthly (due day 1)');
    });
  });
});
