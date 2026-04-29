import { describe, it, expect } from "vitest";
import { applyPayeeRules, applyPayeeRulesToAll, normalizePayeeKey } from "./applyPayeeRules";
import type { PayeeRule } from "../../db/db";

const rule = (over: Partial<PayeeRule> = {}): PayeeRule => ({
  id: over.id || "rule-1",
  householdId: "h",
  pattern: over.pattern || "",
  matchType: over.matchType || "contains",
  payeeOverride: over.payeeOverride,
  category: over.category,
  createdAt: "2026-04-28T00:00:00Z",
  updatedAt: "2026-04-28T00:00:00Z",
});

describe("applyPayeeRules", () => {
  it("normalizes punctuation and whitespace", () => {
    expect(normalizePayeeKey("STARBUCKS  #1234, Boston!")).toBe("starbucks 1234 boston");
    expect(normalizePayeeKey("  AMZN MKTP US*1A2B3  ")).toBe("amzn mktp us 1a2b3");
  });

  it("matches by substring (contains) and applies overrides", () => {
    const r = rule({ id: "r1", pattern: "starbucks", matchType: "contains", payeeOverride: "Starbucks", category: "food" });
    const out = applyPayeeRules<{ payee: string; category?: string }>({ payee: "STARBUCKS #1234 BOSTON" }, [r]);
    expect(out.matchedRuleId).toBe("r1");
    expect(out.draft.payee).toBe("Starbucks");
    expect(out.draft.category).toBe("food");
  });

  it("matches by exact only when normalized key equals pattern", () => {
    const r = rule({ id: "r1", pattern: "amzn mktp us", matchType: "exact", category: "subscriptions" });
    expect(applyPayeeRules({ payee: "AMZN Mktp US" }, [r]).matchedRuleId).toBe("r1");
    expect(applyPayeeRules({ payee: "AMZN MKTP US 1A2B3" }, [r]).matchedRuleId).toBeNull();
  });

  it("first matching rule wins", () => {
    const rules = [
      rule({ id: "r1", pattern: "starbucks", category: "food" }),
      rule({ id: "r2", pattern: "starbucks", category: "other" }),
    ];
    const out = applyPayeeRules<{ payee: string; category?: string }>({ payee: "Starbucks #1" }, rules);
    expect(out.matchedRuleId).toBe("r1");
    expect(out.draft.category).toBe("food");
  });

  it("returns the original draft when no rule matches", () => {
    const out = applyPayeeRules({ payee: "Local Diner", category: "food" }, [rule({ pattern: "starbucks" })]);
    expect(out.matchedRuleId).toBeNull();
    expect(out.draft.payee).toBe("Local Diner");
  });

  it("preserves existing category when rule has no category", () => {
    const r = rule({ pattern: "amazon", payeeOverride: "Amazon" });
    const out = applyPayeeRules<{ payee: string; category?: string }>(
      { payee: "Amazon Prime Charge", category: "shopping" },
      [r],
    );
    expect(out.draft.payee).toBe("Amazon");
    expect(out.draft.category).toBe("shopping");
  });

  it("ignores empty patterns", () => {
    const out = applyPayeeRules({ payee: "Anything" }, [rule({ pattern: "" })]);
    expect(out.matchedRuleId).toBeNull();
  });

  it("applyPayeeRulesToAll preserves order", () => {
    const rules = [rule({ id: "r1", pattern: "amazon", category: "shopping" })];
    const out = applyPayeeRulesToAll([{ payee: "Amazon" }, { payee: "Local" }, { payee: "Amazon Prime" }], rules);
    expect(out.map((x) => x.matchedRuleId)).toEqual(["r1", null, "r1"]);
  });
});
