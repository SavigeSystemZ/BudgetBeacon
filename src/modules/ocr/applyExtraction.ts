import { db } from "../../db/db";
import { createId } from "../../lib/ids/createId";
import type { ExtractedField } from "./types";

/**
 * Extract application handlers — convert extraction fields into db records.
 *
 * The extraction UI passes approved fields + documentId. This module
 * determines the record type and commits to the appropriate table with
 * provenance (documentId link).
 *
 * No auto-detection of record type; caller provides a `hint`.
 */

export interface CommitExtractionOptions {
  householdId: string;
  personId: string;
  documentId: string;
  hint?: "paystub" | "bill" | "bank-statement" | "tax-form" | "unknown";
}

export async function applyExtractionToDb(
  fields: ExtractedField[],
  opts: CommitExtractionOptions
): Promise<{ recordId: string; recordType: string }> {
  const { householdId, personId, documentId, hint } = opts;

  // Build a field map for easier lookup
  const fieldsByKind = new Map<string, ExtractedField>();
  const fieldsByLabel = new Map<string, ExtractedField>();
  fields.forEach((f) => {
    fieldsByKind.set(f.kind, f);
    fieldsByLabel.set(f.label.toLowerCase(), f);
  });

  const getFieldValue = (kind: string, label: string): string | null => {
    const byKind = fieldsByKind.get(kind);
    if (byKind) return byKind.value;
    const byLabel = fieldsByLabel.get(label.toLowerCase());
    return byLabel?.value ?? null;
  };

  // Hint-based routing — if no hint, try to infer from fields present
  const recordType = hint || inferRecordType(fields);

  if (recordType === "paystub" || recordType === "bank-statement") {
    // Likely an income source
    const amount = getFieldValue("amount", "amount");
    const payee = getFieldValue("payee", "payer / issuer");

    if (!amount) throw new Error("Income extraction missing required 'amount' field");

    const recordId = createId();
    await db.incomeSources.add({
      id: recordId,
      householdId,
      personId,
      label: payee || "Extracted Income",
      amount: parseFloat(amount),
      frequency: "monthly",
      isActive: true,
      notes: `OCR extraction from document ${documentId.slice(0, 8)}`,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });

    return { recordId, recordType: "incomeSources" };
  }

  if (recordType === "bill") {
    // Bill extraction
    const amount = getFieldValue("amount", "amount");
    const payee = getFieldValue("payee", "payer / issuer");

    if (!amount) throw new Error("Bill extraction missing required 'amount' field");

    const recordId = createId();
    await db.bills.add({
      id: recordId,
      householdId,
      ownerPersonId: personId,
      label: payee || "Extracted Bill",
      category: "other",
      amount: parseFloat(amount),
      frequency: "monthly",
      dueDay: 15,
      autopay: false,
      isEssential: false,
      notes: `OCR extraction from document ${documentId.slice(0, 8)}`,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });

    return { recordId, recordType: "bills" };
  }

  if (recordType === "tax-form") {
    // Tax record extraction
    const amount = getFieldValue("amount", "amount");
    const year = extractYear(getFieldValue("date", "date"));

    if (!amount || !year) throw new Error("Tax extraction missing 'amount' or 'date' field");

    const recordId = createId();
    await db.taxRecords.add({
      id: recordId,
      householdId,
      personId,
      year,
      estimatedTaxLiability: parseFloat(amount),
      totalWithheld: 0, // User fills in after
      status: "draft",
      notes: `OCR extraction from document ${documentId.slice(0, 8)}`,
    });

    return { recordId, recordType: "taxRecords" };
  }

  // Fallback: if we can't determine type, store as a note in the document
  throw new Error(
    `Unable to determine record type from fields. Hint was '${hint}'. Please categorize the extraction manually.`
  );
}

function inferRecordType(fields: ExtractedField[]): string {
  // Heuristic: if we see "Payer / Issuer" it's likely a bill or income.
  // If we see lots of "amount" fields, probably a tax form.
  // This is crude but helps when hint is missing.

  const hasPayeeField = fields.some((f) => f.kind === "payee");
  if (hasPayeeField) return "bill"; // Default guess

  return "unknown";
}

function extractYear(dateStr: string | null): number {
  if (!dateStr) return new Date().getFullYear();

  // Try to extract year from date string
  const match = dateStr.match(/(\d{4})/);
  if (match) return parseInt(match[1], 10);

  return new Date().getFullYear();
}
