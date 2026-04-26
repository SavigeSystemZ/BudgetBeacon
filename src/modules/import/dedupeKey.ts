/**
 * Canonical string key used to detect duplicate transactions across multiple
 * CSV imports. Two transactions hash to the same key when they share:
 *   - the same calendar date (timezone-stripped, YYYY-MM-DD)
 *   - the same absolute amount, rounded to cents
 *   - the same normalized payee (lowercase, collapsed whitespace, alpha-num only)
 *
 * Stripping payee punctuation lets "AMZN MKTP US*MA1B23" and "Amzn Mktp US ma1b23"
 * collide. The amount is absolute so a refund and the matching original charge
 * collapse — that's intentional for dedupe; the UI lets the user accept both
 * if they really are distinct.
 */

export interface DedupeInput {
  date: string;
  amount: number;
  payee: string;
}

export function dedupeKey(input: DedupeInput): string {
  const date = normalizeDate(input.date);
  const amount = Math.round(Math.abs(input.amount) * 100);
  const payee = normalizePayee(input.payee);
  return `${date}|${amount}|${payee}`;
}

export function normalizeDate(raw: string): string {
  if (!raw) return "";
  // Already in ISO YYYY-MM-DD form?
  if (/^\d{4}-\d{2}-\d{2}/.test(raw)) return raw.slice(0, 10);
  // Try common US format MM/DD/YYYY (or M/D/YY).
  const m = raw.match(/^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})/);
  if (m) {
    let yyyy = m[3];
    if (yyyy.length === 2) yyyy = (Number(yyyy) >= 70 ? "19" : "20") + yyyy;
    const mm = m[1].padStart(2, "0");
    const dd = m[2].padStart(2, "0");
    return `${yyyy}-${mm}-${dd}`;
  }
  // Last-resort: try Date.parse.
  const t = Date.parse(raw);
  if (Number.isFinite(t)) return new Date(t).toISOString().slice(0, 10);
  return raw.trim();
}

export function normalizePayee(raw: string): string {
  return raw
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

/**
 * Parse an amount cell. Tolerates:
 *   - "$1,234.56"
 *   - "(123.45)"  (accounting negative)
 *   - "1.234,56"  (european; only when no '.' decimal pattern matches)
 *   - "+42.00"
 * Returns 0 when input is unparseable.
 */
export function parseAmount(raw: string): number {
  if (!raw) return 0;
  let s = raw.trim();
  let negative = false;

  // Accounting-style parens: (123.45) → -123.45
  const parens = s.match(/^\((.+)\)$/);
  if (parens) {
    negative = true;
    s = parens[1];
  }
  // Strip currency symbols and explicit + sign.
  s = s.replace(/[$€£¥+\s]/g, "");
  // Leading minus.
  if (s.startsWith("-")) {
    negative = !negative;
    s = s.slice(1);
  }

  // Decide decimal separator: if the string has both ',' and '.', the rightmost wins.
  // If only ',', treat as decimal when followed by exactly two digits.
  const lastComma = s.lastIndexOf(",");
  const lastDot = s.lastIndexOf(".");
  if (lastComma > -1 && lastDot > -1) {
    if (lastComma > lastDot) {
      s = s.replace(/\./g, "").replace(",", ".");
    } else {
      s = s.replace(/,/g, "");
    }
  } else if (lastComma > -1 && lastDot === -1) {
    // 1.234,56 style or 1,234 style. If the part after comma is 1-2 digits, treat as decimal.
    const tail = s.slice(lastComma + 1);
    if (tail.length === 2 && /^\d{2}$/.test(tail)) {
      s = s.replace(/\./g, "").replace(",", ".");
    } else {
      s = s.replace(/,/g, "");
    }
  }

  const n = Number(s);
  if (!Number.isFinite(n)) return 0;
  return negative ? -n : n;
}
