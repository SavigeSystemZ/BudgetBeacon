import { describe, it, expect } from "vitest";
import { escapeCsvCell, rowsToCsv } from "./csv";

describe("CSV helpers", () => {
  it("passes simple values through unquoted", () => {
    expect(escapeCsvCell("hello")).toBe("hello");
    expect(escapeCsvCell(42)).toBe("42");
    expect(escapeCsvCell(true)).toBe("true");
  });

  it("represents null/undefined as empty", () => {
    expect(escapeCsvCell(null)).toBe("");
    expect(escapeCsvCell(undefined)).toBe("");
  });

  it("quotes cells containing comma / quote / newline", () => {
    expect(escapeCsvCell("a,b")).toBe('"a,b"');
    expect(escapeCsvCell('he said "hi"')).toBe('"he said ""hi"""');
    expect(escapeCsvCell("line1\nline2")).toBe('"line1\nline2"');
  });

  it("rowsToCsv emits header + rows with CRLF and trailing newline", () => {
    const csv = rowsToCsv(["payee", "amount"], [
      ["Coffee", 4.5],
      ["Rent, monthly", 1200],
    ]);
    expect(csv).toBe('payee,amount\r\nCoffee,4.5\r\n"Rent, monthly",1200\r\n');
  });
});
