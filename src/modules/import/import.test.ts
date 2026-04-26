import { describe, it, expect } from "vitest";
import { parseCsv } from "./parseCsv";
import { dedupeKey, normalizeDate, normalizePayee, parseAmount } from "./dedupeKey";
import { mapRowsToDrafts, partitionByDedupe } from "./mapRows";

describe("parseCsv", () => {
  it("parses a simple bank CSV with quoted fields", () => {
    const text = `Date,Description,Amount\n2026-01-15,"AMZN, MKTP",-42.99\n2026-01-16,Paycheck,2500\n`;
    const out = parseCsv(text);
    expect(out.headers).toEqual(["Date", "Description", "Amount"]);
    expect(out.rows).toHaveLength(2);
    expect(out.rows[0]).toEqual({ Date: "2026-01-15", Description: "AMZN, MKTP", Amount: "-42.99" });
    expect(out.rows[1].Description).toBe("Paycheck");
  });

  it("handles CRLF line endings + trailing newline", () => {
    const text = `a,b\r\n1,2\r\n3,4\r\n`;
    const out = parseCsv(text);
    expect(out.rows).toEqual([{ a: "1", b: "2" }, { a: "3", b: "4" }]);
  });

  it("handles embedded quotes and newlines inside quoted fields", () => {
    const text = `note\n"line1\nline2 ""quoted"""\n`;
    const out = parseCsv(text);
    expect(out.rows[0].note).toBe('line1\nline2 "quoted"');
  });

  it("strips a UTF-8 BOM if present", () => {
    const text = `﻿a,b\n1,2\n`;
    const out = parseCsv(text);
    expect(out.headers).toEqual(["a", "b"]);
    expect(out.rows[0]).toEqual({ a: "1", b: "2" });
  });

  it("returns empty result for empty input", () => {
    expect(parseCsv("")).toEqual({ headers: [], rows: [] });
  });
});

describe("normalizeDate", () => {
  it("passes ISO date through", () => {
    expect(normalizeDate("2026-01-15")).toBe("2026-01-15");
  });
  it("converts MM/DD/YYYY", () => {
    expect(normalizeDate("01/15/2026")).toBe("2026-01-15");
    expect(normalizeDate("1/5/2026")).toBe("2026-01-05");
  });
  it("converts MM/DD/YY (2-digit year, 2000-cutoff at 70)", () => {
    expect(normalizeDate("01/15/26")).toBe("2026-01-15");
    expect(normalizeDate("01/15/85")).toBe("1985-01-15");
  });
  it("returns trimmed input for unrecognized formats", () => {
    expect(normalizeDate("garbage")).toBe("garbage");
  });
});

describe("normalizePayee", () => {
  it("collapses casing, punctuation, and whitespace", () => {
    expect(normalizePayee("AMZN MKTP US*MA1B23")).toBe("amzn mktp us ma1b23");
    expect(normalizePayee("Amzn  Mktp   US   MA1B23")).toBe("amzn mktp us ma1b23");
  });
});

describe("parseAmount", () => {
  it("parses plain numbers", () => {
    expect(parseAmount("42.99")).toBe(42.99);
    expect(parseAmount("-42.99")).toBe(-42.99);
  });
  it("strips currency and thousands separators", () => {
    expect(parseAmount("$1,234.56")).toBe(1234.56);
    expect(parseAmount("€1.234,56")).toBe(1234.56);
  });
  it("treats accounting parens as negative", () => {
    expect(parseAmount("(123.45)")).toBe(-123.45);
  });
  it("returns 0 for empty / unparseable", () => {
    expect(parseAmount("")).toBe(0);
    expect(parseAmount("garbage")).toBe(0);
  });
});

describe("dedupeKey", () => {
  it("produces equal keys for ostensibly-same transactions", () => {
    const a = dedupeKey({ date: "2026-01-15", amount: -42.99, payee: "AMZN MKTP US*MA1B23" });
    const b = dedupeKey({ date: "01/15/2026", amount: 42.99, payee: "Amzn Mktp US ma1b23" });
    expect(a).toBe(b);
  });
  it("differs for different dates", () => {
    const a = dedupeKey({ date: "2026-01-15", amount: 10, payee: "X" });
    const b = dedupeKey({ date: "2026-01-16", amount: 10, payee: "X" });
    expect(a).not.toBe(b);
  });
});

describe("mapRowsToDrafts", () => {
  const mapping = { date: "Date", payee: "Description", amount: "Amount" };

  it("converts rows and infers type from sign", () => {
    const rows = [
      { Date: "2026-01-15", Description: "Amazon", Amount: "-42.99" },
      { Date: "2026-01-16", Description: "Paycheck", Amount: "2500" },
    ];
    const { drafts, skipped } = mapRowsToDrafts(rows, mapping);
    expect(skipped).toEqual([]);
    expect(drafts).toHaveLength(2);
    expect(drafts[0].type).toBe("expense");
    expect(drafts[0].amount).toBe(42.99);
    expect(drafts[1].type).toBe("income");
    expect(drafts[1].amount).toBe(2500);
  });

  it("collects skips with a row number for unparseable dates / amounts", () => {
    const rows = [
      { Date: "garbage", Description: "x", Amount: "10" },
      { Date: "2026-01-15", Description: "y", Amount: "" },
    ];
    const { drafts, skipped } = mapRowsToDrafts(rows, mapping);
    expect(drafts).toEqual([]);
    expect(skipped).toHaveLength(2);
    expect(skipped[0].row).toBe(2);
    expect(skipped[1].row).toBe(3);
  });

  it("respects an explicit type column when provided", () => {
    const rows = [{ Date: "2026-01-15", Description: "X", Amount: "100", T: "credit" }];
    const { drafts } = mapRowsToDrafts(rows, { ...mapping, type: "T" });
    expect(drafts[0].type).toBe("income");
  });
});

describe("partitionByDedupe", () => {
  it("separates fresh drafts from duplicates", () => {
    const drafts = [
      {
        date: "2026-01-15", payee: "A", amount: 10, category: "x",
        type: "expense" as const, dedupeKey: "k1", sourceRow: 2,
      },
      {
        date: "2026-01-16", payee: "B", amount: 20, category: "x",
        type: "expense" as const, dedupeKey: "k2", sourceRow: 3,
      },
    ];
    const { fresh, duplicates } = partitionByDedupe(drafts, new Set(["k2"]));
    expect(fresh.map((d) => d.payee)).toEqual(["A"]);
    expect(duplicates.map((d) => d.payee)).toEqual(["B"]);
  });
});
