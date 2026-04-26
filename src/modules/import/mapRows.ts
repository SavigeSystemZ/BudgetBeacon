import { dedupeKey, normalizeDate, parseAmount } from "./dedupeKey";

/**
 * User-supplied mapping from CSV column header → transaction field.
 *
 * Type and category are optional — "type" defaults to expense for negative
 * amounts and income for positive amounts; "category" defaults to "uncategorized".
 */
export interface ColumnMapping {
  date: string;
  payee: string;
  amount: string;
  category?: string;
  type?: string;
}

export interface MappedTransactionDraft {
  date: string;          // YYYY-MM-DD
  payee: string;         // raw, untransformed for display
  amount: number;        // absolute value (sign captured in `type`)
  category: string;
  type: "income" | "expense";
  dedupeKey: string;
  sourceRow: number;     // 1-indexed for user error messages
}

/**
 * Convert a parsed CSV (header → string map) into typed transaction drafts
 * ready for the review queue. Skips rows where date or amount can't be parsed.
 */
export function mapRowsToDrafts(
  rows: Record<string, string>[],
  mapping: ColumnMapping
): { drafts: MappedTransactionDraft[]; skipped: { row: number; reason: string }[] } {
  const drafts: MappedTransactionDraft[] = [];
  const skipped: { row: number; reason: string }[] = [];

  rows.forEach((raw, idx) => {
    const sourceRow = idx + 2; // +1 for header, +1 for 1-indexed
    const dateRaw = raw[mapping.date] ?? "";
    const date = normalizeDate(dateRaw);
    if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      skipped.push({ row: sourceRow, reason: `Unparseable date: "${dateRaw}"` });
      return;
    }

    const amountRaw = raw[mapping.amount] ?? "";
    const signedAmount = parseAmount(amountRaw);
    if (signedAmount === 0 && amountRaw.trim() === "") {
      skipped.push({ row: sourceRow, reason: "Empty amount" });
      return;
    }

    const payee = (raw[mapping.payee] ?? "").trim();
    const explicitType = mapping.type ? raw[mapping.type]?.trim().toLowerCase() : undefined;
    const type: "income" | "expense" =
      explicitType === "income" || explicitType === "credit"
        ? "income"
        : explicitType === "expense" || explicitType === "debit"
        ? "expense"
        : signedAmount >= 0
        ? "income"
        : "expense";

    const category = (mapping.category && raw[mapping.category]?.trim()) || "uncategorized";
    const amount = Math.abs(signedAmount);

    drafts.push({
      date,
      payee,
      amount,
      category,
      type,
      dedupeKey: dedupeKey({ date, amount, payee }),
      sourceRow,
    });
  });

  return { drafts, skipped };
}

/**
 * Partition drafts against a set of existing dedupe keys (computed from current
 * db transactions). Returns fresh-vs-duplicate so the review UI can default
 * duplicates to "skip" while keeping them visible.
 */
export function partitionByDedupe(
  drafts: MappedTransactionDraft[],
  existingKeys: Set<string>
): { fresh: MappedTransactionDraft[]; duplicates: MappedTransactionDraft[] } {
  const fresh: MappedTransactionDraft[] = [];
  const duplicates: MappedTransactionDraft[] = [];
  for (const d of drafts) {
    if (existingKeys.has(d.dedupeKey)) duplicates.push(d);
    else fresh.push(d);
  }
  return { fresh, duplicates };
}
