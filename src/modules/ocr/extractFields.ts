import type { ExtractedField } from "./types";
import { normalizeDate, parseAmount } from "../import/dedupeKey";

/**
 * Pure, testable structured-field extractor. Takes raw OCR text and returns a
 * best-effort list of ExtractedField guesses (date, amount, payee/label).
 *
 * No regex magic beyond what's needed — the user always reviews and corrects
 * before commit (per docs/INTEGRATIONS_STRATEGY.md Domain 2 §UI handling).
 */

const DATE_RE = /\b(\d{4}-\d{2}-\d{2}|\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}|(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*\s+\d{1,2},?\s+\d{2,4})\b/gi;
// Money: optional currency, optional thousands sep, mandatory cents.
const MONEY_RE = /(?:\$|USD\s*)?\d{1,3}(?:,\d{3})*\.\d{2}\b|\b\d+\.\d{2}\b/g;
const AMOUNT_LINE_RE = /\b(?:amount|total|payment|balance due|due|monthly|gross|net pay|pay)\b\s*[:=]?\s*\$?(\d{1,3}(?:,\d{3})*\.\d{2}|\d+\.\d{2})/gi;
const PAYER_LINE_RE = /\b(?:from|payer|issued by|issuer|provider|merchant)\b\s*[:\-]\s*([^\n]{3,80})/gi;

export function extractFields(rawText: string): ExtractedField[] {
  const fields: ExtractedField[] = [];

  // 1. Best date — prefer the first ISO match, else first US-format match.
  const dateMatch = pickBestDate(rawText);
  if (dateMatch) {
    fields.push({ kind: "date", label: "Date", value: dateMatch });
  }

  // 2. Best amount — prefer one labeled "amount/total/payment/due", else the
  //    largest plain money figure in the doc.
  const amountMatch = pickBestAmount(rawText);
  if (amountMatch !== null) {
    fields.push({ kind: "amount", label: "Amount", value: amountMatch.toFixed(2) });
  }

  // 3. Payee / issuer — explicit "From:" line wins; otherwise the first line.
  const payee = pickBestPayee(rawText);
  if (payee) {
    fields.push({ kind: "payee", label: "Payer / Issuer", value: payee });
  }

  return fields;
}

function pickBestDate(text: string): string | null {
  const matches = Array.from(text.matchAll(DATE_RE)).map((m) => m[1]);
  if (matches.length === 0) return null;
  // Prefer ISO; otherwise normalize the first.
  const iso = matches.find((m) => /^\d{4}-\d{2}-\d{2}$/.test(m));
  if (iso) return iso;
  const normalized = normalizeDate(matches[0]);
  return /^\d{4}-\d{2}-\d{2}$/.test(normalized) ? normalized : matches[0];
}

function pickBestAmount(text: string): number | null {
  const labeled = Array.from(text.matchAll(AMOUNT_LINE_RE)).map((m) => parseAmount(m[1]));
  if (labeled.length > 0) {
    // Take the largest labeled value (likely the total / gross / payment).
    return Math.max(...labeled);
  }
  const all = Array.from(text.matchAll(MONEY_RE)).map((m) => parseAmount(m[0]));
  if (all.length === 0) return null;
  return Math.max(...all);
}

function pickBestPayee(text: string): string | null {
  const explicit = Array.from(text.matchAll(PAYER_LINE_RE))[0];
  if (explicit) return explicit[1].trim();

  // Fallback: first non-empty meaningful line that isn't all digits / a date.
  const lines = text
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter((l) => l.length > 2 && !/^\d+([.,]\d+)?$/.test(l) && !DATE_RE.test(l));
  if (lines.length === 0) return null;
  return lines[0].slice(0, 80);
}
