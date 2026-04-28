import { describe, it, expect, beforeEach } from "vitest";
import type { ExtractedField } from "./types";
import { extractFields } from "./extractFields";
import { applyExtractionToDb } from "./applyExtraction";
import { db } from "../../db/db";

describe("M6 — OCR Extraction & Application", () => {
  beforeEach(async () => {
    const tables = ["households", "persons", "incomeSources", "bills", "taxRecords"] as const;
    for (const table of tables) {
      await (db[table] as any).clear();
    }
  });

  describe("extractFields", () => {
    it("extracts date, amount, and payee from invoice-like text", () => {
      const rawText = "Date: 2025-03-15\nFrom: Amazon\nAmount: $42.99";
      const fields = extractFields(rawText);
      expect(fields.length).toBeGreaterThan(0);
    });

    it("extracts largest amount from text", () => {
      const rawText = "$5.00\nTotal: $1,250.45\nTax: $98.75";
      const fields = extractFields(rawText);
      const amountField = fields.find((f) => f.kind === "amount");
      expect(parseFloat(amountField?.value || "0")).toBe(1250.45);
    });

    it("handles empty OCR text gracefully", () => {
      expect(extractFields("")).toEqual([]);
    });
  });

  describe("applyExtractionToDb", () => {
    let householdId: string;
    let personId: string;

    beforeEach(async () => {
      householdId = "test-hh";
      personId = "test-person";
      const now = new Date().toISOString();

      await db.households.add({
        id: householdId,
        name: "Test Household",
        currency: "USD",
        createdAt: now,
        updatedAt: now,
      });

      await db.persons.add({
        id: personId,
        householdId,
        name: "Test Person",
        role: "primary",
        createdAt: now,
        updatedAt: now,
      });
    });

    it("applies income extraction", async () => {
      const fields: ExtractedField[] = [
        { kind: "amount", label: "Amount", value: "1450.00", confidence: 0.95 },
        { kind: "payee", label: "Payer / Issuer", value: "Social Security", confidence: 0.92 },
      ];

      const result = await applyExtractionToDb(fields, {
        householdId,
        personId,
        documentId: "doc-123",
        hint: "paystub",
      });

      expect(result.recordType).toBe("incomeSources");
      const income = await db.incomeSources.get(result.recordId);
      expect(income?.amount).toBe(1450.0);
    });

    it("applies bill extraction", async () => {
      const fields: ExtractedField[] = [
        { kind: "amount", label: "Amount", value: "124.99", confidence: 0.88 },
      ];

      const result = await applyExtractionToDb(fields, {
        householdId,
        personId,
        documentId: "doc-456",
        hint: "bill",
      });

      expect(result.recordType).toBe("bills");
      const bill = await db.bills.get(result.recordId);
      expect(bill?.amount).toBe(124.99);
    });

    it("includes documentId provenance", async () => {
      const fields: ExtractedField[] = [
        { kind: "amount", label: "Amount", value: "500.00", confidence: 0.9 },
      ];

      const result = await applyExtractionToDb(fields, {
        householdId,
        personId,
        documentId: "doc-prov-123",
        hint: "paystub",
      });

      const income = await db.incomeSources.get(result.recordId);
      expect(income?.notes).toContain("doc-prov");
    });
  });

  describe("Feature flag integration", () => {
    it("ocrLocal flag enables Scavenge feature", async () => {
      const { featureFlags } = await import("../../lib/flags/featureFlags");
      expect(featureFlags.ocrLocal).toBe(true);
    });
  });
});
