import { describe, it, expect, vi } from "vitest";
import type { AssistantContextFacts } from "../modules/ai/contextBuilder";

const { buildAssistantContextMock } = vi.hoisted(() => ({
  buildAssistantContextMock: vi.fn(),
}));

vi.mock("../modules/ai/contextBuilder", () => ({
  buildAssistantContext: buildAssistantContextMock,
}));

import { beaconPlaceholderReply } from "../modules/ai/beaconPlaceholderReply";

function makeFacts(overrides: Partial<AssistantContextFacts> = {}): AssistantContextFacts {
  return {
    monthlyIncome: 4000,
    monthlyBills: 1500,
    monthlyDebtMin: 300,
    monthlySubs: 50,
    monthlyInsurance: 120,
    netMonthly: 600,
    activeGoals: 2,
    stabilityIndex: 78,
    stabilityLabel: "Stable",
    monthPrefix: "2026-05",
    mtdExpenseTotal: 450,
    mtdExpenseRowCount: 4,
    topExpenseCategories: [
      { category: "Food", total: 200 },
      { category: "Gas", total: 150 },
      { category: "Utilities", total: 100 },
    ],
    budgetStatus: "YELLOW",
    taxRecordCount: 0,
    taxFormCount: 0,
    vaultDocumentCount: 0,
    payeeRuleCount: 0,
    ...overrides,
  };
}

describe("beaconPlaceholderReply", () => {
  it("includes insurance and top category MTD lines when data exists", async () => {
    buildAssistantContextMock.mockResolvedValueOnce({
      systemPrompt: "ignored",
      facts: makeFacts(),
    });

    const text = await beaconPlaceholderReply("show spend categories");
    expect(text).toContain("Insurance (rolled to monthly):");
    expect(text).toContain("MTD ledger spend (2026-05):");
    expect(text).toContain("Food");
    expect(text).toContain("Dashboard for the MTD expense donut");
  });

  it("emits no-expense guidance when month has no expense rows", async () => {
    buildAssistantContextMock.mockResolvedValueOnce({
      systemPrompt: "ignored",
      facts: makeFacts({
        mtdExpenseTotal: 0,
        mtdExpenseRowCount: 0,
        topExpenseCategories: [],
      }),
    });

    const text = await beaconPlaceholderReply("any update?");
    expect(text).toContain("MTD ledger (2026-05): no expense rows yet");
    expect(text).toContain('Configure a model in Settings to get a real conversational answer to "any update?".');
  });

  it("emits cut/save guidance when user asks reduction question", async () => {
    buildAssistantContextMock.mockResolvedValueOnce({
      systemPrompt: "ignored",
      facts: makeFacts(),
    });

    const text = await beaconPlaceholderReply("where can I cut spending?");
    expect(text).toContain("For real recommendations, configure a model in Settings");
    expect(text).toContain("Mission Control and Reports screens");
  });

  it("includes tax/vault/payee rule row counts when present", async () => {
    buildAssistantContextMock.mockResolvedValueOnce({
      systemPrompt: "ignored",
      facts: makeFacts({ taxFormCount: 2, vaultDocumentCount: 1, payeeRuleCount: 4 }),
    });

    const text = await beaconPlaceholderReply("status");
    expect(text).toContain("Other telemetry rows:");
    expect(text).toContain("tax forms 2");
    expect(text).toContain("vault docs 1");
    expect(text).toContain("payee rules 4");
  });
});
