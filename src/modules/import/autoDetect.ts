import type { ColumnMapping } from "./mapRows";

/**
 * Best-effort guess at the {date, payee, amount} → header mapping.
 * The user can override every guess in the import-mapping step.
 */
const DATE_HINTS = ["date", "posted", "trans date", "transaction date", "post date"];
const PAYEE_HINTS = ["description", "payee", "memo", "merchant", "name", "details"];
const AMOUNT_HINTS = ["amount", "debit", "credit", "value", "transaction amount"];
const CATEGORY_HINTS = ["category", "type", "tag"];
const TYPE_HINTS = ["type", "transaction type"];

function pick(headers: string[], hints: string[]): string | undefined {
  const lowered = headers.map((h) => h.toLowerCase());
  for (const hint of hints) {
    const i = lowered.indexOf(hint);
    if (i !== -1) return headers[i];
  }
  // Substring match as fallback (e.g. "Posted Date").
  for (const hint of hints) {
    const i = lowered.findIndex((h) => h.includes(hint));
    if (i !== -1) return headers[i];
  }
  return undefined;
}

export function autoDetectMapping(headers: string[]): Partial<ColumnMapping> {
  return {
    date: pick(headers, DATE_HINTS),
    payee: pick(headers, PAYEE_HINTS),
    amount: pick(headers, AMOUNT_HINTS),
    category: pick(headers, CATEGORY_HINTS),
    type: pick(headers, TYPE_HINTS),
  };
}
