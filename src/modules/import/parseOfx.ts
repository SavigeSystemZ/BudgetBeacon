/**
 * OFX / QFX parser. Both formats use the same SGML-ish body; QFX is just OFX
 * with a Quicken-specific `INTU.BID` / `INTU.USERID` extension we ignore.
 *
 * We extract `<STMTTRN>` (and `<CCSTMTTRN>` for credit-card files) blocks and
 * surface them as `MappedTransactionDraft` rows so they flow through the same
 * dedupe / review pipeline as CSV imports.
 *
 * This is intentionally a tolerant parser — real-world bank exports drop
 * close tags, mix line endings, and sometimes wrap values in CDATA. We strip
 * the SGML header, split on `<STMTTRN>` / `</STMTTRN>` markers, and read each
 * tag with a single regex per field. We do NOT try to validate against the
 * OFX 1.0 / 2.0 DTD — that would reject too many real files.
 */

import type { MappedTransactionDraft } from "./mapRows";
import { dedupeKey } from "./dedupeKey";

type TransactionType = "income" | "expense";

export interface OfxParseResult {
  drafts: MappedTransactionDraft[];
  skipped: Array<{ blockIndex: number; reason: string }>;
  meta: {
    accountId?: string;
    accountType?: string; // CHECKING | SAVINGS | CREDITCARD etc.
    currency?: string;
  };
}

/**
 * Parse an OFX or QFX file body. Returns drafts ready for the same review
 * queue used by CSV imports.
 */
export function parseOfx(text: string): OfxParseResult {
  const body = stripHeader(text);

  const meta: OfxParseResult["meta"] = {
    accountId: tagValue(body, "ACCTID") || tagValue(body, "BANKACCTFROM/ACCTID"),
    accountType: tagValue(body, "ACCTTYPE"),
    currency: tagValue(body, "CURDEF"),
  };

  const blocks = extractBlocks(body, "STMTTRN");
  const ccBlocks = extractBlocks(body, "CCSTMTTRN");
  const all = [...blocks, ...ccBlocks];

  const drafts: MappedTransactionDraft[] = [];
  const skipped: OfxParseResult["skipped"] = [];

  all.forEach((block, idx) => {
    const dateRaw = tagValue(block, "DTPOSTED") || tagValue(block, "DTUSER");
    const amtRaw = tagValue(block, "TRNAMT");
    const name = tagValue(block, "NAME") || tagValue(block, "PAYEE/NAME") || tagValue(block, "MEMO") || "";
    const memo = tagValue(block, "MEMO");

    if (!dateRaw) {
      skipped.push({ blockIndex: idx, reason: "missing DTPOSTED" });
      return;
    }
    if (!amtRaw) {
      skipped.push({ blockIndex: idx, reason: "missing TRNAMT" });
      return;
    }

    const isoDate = parseOfxDate(dateRaw);
    if (!isoDate) {
      skipped.push({ blockIndex: idx, reason: `unrecognized date "${dateRaw}"` });
      return;
    }

    const amt = parseFloat(amtRaw);
    if (!Number.isFinite(amt)) {
      skipped.push({ blockIndex: idx, reason: `unrecognized amount "${amtRaw}"` });
      return;
    }

    const payee = (name || memo || "Unknown").trim();
    const type: TransactionType = amt < 0 ? "expense" : "income";
    const absAmount = Math.abs(amt);

    drafts.push({
      date: isoDate,
      payee,
      amount: absAmount,
      category: "other",
      type,
      dedupeKey: dedupeKey({ date: isoDate, amount: absAmount, payee }),
      sourceRow: idx + 1,
    });
  });

  return { drafts, skipped, meta };
}

/**
 * OFX date format is YYYYMMDDHHMMSS[.XXX][TZ]. The simplest case is just
 * YYYYMMDD. We return ISO yyyy-mm-dd (date only — Beacon transactions are
 * day-grain).
 */
export function parseOfxDate(raw: string): string | null {
  const m = raw.match(/^(\d{4})(\d{2})(\d{2})/);
  if (!m) return null;
  const [, y, mo, d] = m;
  if (parseInt(mo, 10) < 1 || parseInt(mo, 10) > 12) return null;
  if (parseInt(d, 10) < 1 || parseInt(d, 10) > 31) return null;
  return `${y}-${mo}-${d}`;
}

/** Strip the SGML / XML preamble so tag scanning starts in the OFX body. */
export function stripHeader(text: string): string {
  // OFX 1.x uses an "OFXHEADER:..." block followed by a blank line.
  const lines = text.split(/\r?\n/);
  let i = 0;
  while (i < lines.length && /^[A-Z]+:/.test(lines[i])) i++;
  while (i < lines.length && lines[i].trim() === "") i++;
  let body = lines.slice(i).join("\n");

  // OFX 2.x uses an XML prolog. Drop everything up to the first <OFX>.
  const ofxStart = body.search(/<OFX[ >]/i);
  if (ofxStart > 0) body = body.slice(ofxStart);
  return body;
}

/** Return the first `<TAG>value</TAG>` (or `<TAG>value` SGML form) match. */
export function tagValue(body: string, path: string): string | undefined {
  // Support nested paths like "BANKACCTFROM/ACCTID" by walking.
  const segments = path.split("/");
  let scope = body;
  for (let i = 0; i < segments.length - 1; i++) {
    const inner = matchBlock(scope, segments[i]);
    if (!inner) return undefined;
    scope = inner;
  }
  const tag = segments[segments.length - 1];
  // Closing-tag form `<TAG>value</TAG>` and SGML form `<TAG>value\n` both work.
  const re = new RegExp(`<${tag}>([^<\\n\\r]*)`, "i");
  const m = scope.match(re);
  if (!m) return undefined;
  return decodeEntities(m[1].trim()) || undefined;
}

function matchBlock(body: string, tag: string): string | undefined {
  const re = new RegExp(`<${tag}>([\\s\\S]*?)</${tag}>`, "i");
  const m = body.match(re);
  return m?.[1];
}

/** Extract every `<TAG>...</TAG>` block at any depth. */
export function extractBlocks(body: string, tag: string): string[] {
  const re = new RegExp(`<${tag}>([\\s\\S]*?)</${tag}>`, "gi");
  const out: string[] = [];
  let m: RegExpExecArray | null;
  while ((m = re.exec(body)) !== null) out.push(m[1]);
  return out;
}

function decodeEntities(s: string): string {
  return s
    .replace(/&amp;/gi, "&")
    .replace(/&lt;/gi, "<")
    .replace(/&gt;/gi, ">")
    .replace(/&quot;/gi, '"')
    .replace(/&apos;/gi, "'");
}
