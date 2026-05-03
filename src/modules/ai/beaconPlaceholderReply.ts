import { buildAssistantContext } from "./contextBuilder";

/**
 * No-provider fallback for the Beacon assistant. Uses real aggregates only.
 */
export async function beaconPlaceholderReply(userText: string): Promise<string> {
  const ctx = await buildAssistantContext();
  const f = ctx.facts;
  const fmt = (n: number) =>
    n.toLocaleString("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 });

  const lower = userText.toLowerCase();
  const lines: string[] = [
    "(No model connected — replying from real db aggregates only.)",
    `Monthly income ${fmt(f.monthlyIncome)} · bills ${fmt(f.monthlyBills)} · debt min ${fmt(f.monthlyDebtMin)} · subs ${fmt(f.monthlySubs)}.`,
    `Leftover after required + savings: ${fmt(f.netMonthly)}. Stability index ${f.stabilityIndex}/100 (${f.stabilityLabel}).`,
  ];

  if (f.monthlyInsurance > 0) {
    lines.push(`Insurance (rolled to monthly): ${fmt(f.monthlyInsurance)}.`);
  }

  if (f.taxRecordCount + f.taxFormCount + f.vaultDocumentCount + f.payeeRuleCount > 0) {
    lines.push(
      `Other telemetry rows: Tax years ${f.taxRecordCount}, tax forms ${f.taxFormCount}, vault docs ${f.vaultDocumentCount}, payee rules ${f.payeeRuleCount}.`,
    );
  }

  if (f.mtdExpenseTotal > 0 && f.topExpenseCategories.length > 0) {
    const head = f.topExpenseCategories
      .slice(0, 3)
      .map((c) => `${c.category} ${fmt(c.total)}`)
      .join(" · ");
    lines.push(
      `MTD ledger spend (${f.monthPrefix}): ${fmt(f.mtdExpenseTotal)} — ${head}. Same rollups: Dashboard (donut) · Reports → Monthly · Mission Control.`,
    );
  } else {
    lines.push(`MTD ledger (${f.monthPrefix}): no expense rows yet — log loops in Ledger to unlock category charts.`);
  }

  if (lower.includes("cut") || lower.includes("save") || lower.includes("reduce")) {
    lines.push(
      `For real recommendations, configure a model in Settings → AI Configuration. ` +
        `In the meantime, the Mission Control and Reports screens already surface the highest-leverage cuts based on these numbers.`,
    );
  } else if (lower.includes("stability") || lower.includes("health")) {
    lines.push(`See Mission Control's Stability Index card for the full breakdown.`);
  } else if (
    lower.includes("categor") ||
    lower.includes("spend") ||
    lower.includes("ledger") ||
    lower.includes("expense")
  ) {
    lines.push(
      `Open Dashboard for the MTD expense donut, Reports → Monthly for the printable rollup, or Mission Control for the compact list — all read the same ledger data.`,
    );
  } else {
    lines.push(`Configure a model in Settings to get a real conversational answer to "${userText}".`);
  }

  return lines.join("\n");
}
