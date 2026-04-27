import { describe, it, expect } from "vitest";
import { extractFields } from "./extractFields";

describe("extractFields", () => {
  it("pulls date / amount / payer from a typical award letter", () => {
    const text = `
      Department of Veterans Affairs
      From: VA Regional Office
      Date: 2026-03-15

      Dear Beneficiary,
      Your monthly compensation is $1,450.00.
      Total annual benefit: $17,400.00
    `;
    const fields = extractFields(text);
    const byKind = Object.fromEntries(fields.map((f) => [f.kind, f.value]));
    expect(byKind.date).toBe("2026-03-15");
    // "Total annual benefit" is the largest labeled amount.
    expect(byKind.amount).toBe("17400.00");
    expect(byKind.payee).toBe("VA Regional Office");
  });

  it("returns the largest plain money figure when no labels are present", () => {
    const text = `random thing\n42.99 something\n500.00 else\n`;
    const fields = extractFields(text);
    const amount = fields.find((f) => f.kind === "amount");
    expect(amount?.value).toBe("500.00");
  });

  it("normalizes US-format dates", () => {
    const fields = extractFields("Statement Date: 03/15/2026\nAmount: $42.00");
    const date = fields.find((f) => f.kind === "date");
    expect(date?.value).toBe("2026-03-15");
  });

  it("falls back to the first non-empty line when no payer label is present", () => {
    const fields = extractFields("Acme Utility Co.\n\nAmount due: $87.50\n");
    const payee = fields.find((f) => f.kind === "payee");
    expect(payee?.value).toBe("Acme Utility Co.");
  });

  it("handles empty input gracefully", () => {
    expect(extractFields("")).toEqual([]);
  });
});
