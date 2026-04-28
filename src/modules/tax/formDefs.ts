/**
 * Declarative definitions of the tax forms Budget Beacon supports.
 *
 * The form editor is data-driven from these defs — adding a new form is just
 * an entry here. Persisted shape is `{ id, year, type, data: Record<string, unknown>, updatedAt, personId }`
 * in the existing `taxForms` Dexie table; nothing here implies tax compliance.
 *
 * Honest scope note: these capture line-item entries from real IRS forms so
 * the user can keep all their tax telemetry in one place. They do not file or
 * compute final tax liability — that is for a CPA / TurboTax / etc.
 */

export type TaxFieldType = "text" | "number" | "currency" | "ein" | "tin";

export interface TaxFieldDef {
  key: string;
  label: string;
  type: TaxFieldType;
  helper?: string;
  required?: boolean;
}

export interface TaxFormDef {
  /** Stable code used as the `type` column in taxForms. */
  code: string;
  title: string;
  description: string;
  fields: TaxFieldDef[];
}

export const TAX_FORMS: TaxFormDef[] = [
  {
    code: "w2",
    title: "W-2 — Wage and Tax Statement",
    description: "Employer-issued. One per employer per year.",
    fields: [
      { key: "employerName", label: "Employer name", type: "text", required: true },
      { key: "employerEin", label: "Employer EIN (box b)", type: "ein" },
      { key: "wagesTipsCompensation", label: "Wages, tips, compensation (box 1)", type: "currency", required: true },
      { key: "federalIncomeTaxWithheld", label: "Federal income tax withheld (box 2)", type: "currency" },
      { key: "socialSecurityWages", label: "Social Security wages (box 3)", type: "currency" },
      { key: "socialSecurityTaxWithheld", label: "Social Security tax withheld (box 4)", type: "currency" },
      { key: "medicareWages", label: "Medicare wages (box 5)", type: "currency" },
      { key: "medicareTaxWithheld", label: "Medicare tax withheld (box 6)", type: "currency" },
      { key: "stateWages", label: "State wages (box 16)", type: "currency" },
      { key: "stateIncomeTaxWithheld", label: "State income tax withheld (box 17)", type: "currency" },
    ],
  },
  {
    code: "1099-nec",
    title: "1099-NEC — Nonemployee Compensation",
    description: "Issued by clients to contractors and self-employed individuals.",
    fields: [
      { key: "payerName", label: "Payer name", type: "text", required: true },
      { key: "payerTin", label: "Payer TIN", type: "tin" },
      { key: "nonemployeeCompensation", label: "Nonemployee compensation (box 1)", type: "currency", required: true },
      { key: "federalIncomeTaxWithheld", label: "Federal income tax withheld (box 4)", type: "currency" },
      { key: "stateTaxWithheld", label: "State tax withheld (box 5)", type: "currency" },
      { key: "stateIncome", label: "State income (box 7)", type: "currency" },
    ],
  },
  {
    code: "1099-int",
    title: "1099-INT — Interest Income",
    description: "Issued by banks and brokerages for interest paid.",
    fields: [
      { key: "payerName", label: "Payer name", type: "text", required: true },
      { key: "payerTin", label: "Payer TIN", type: "tin" },
      { key: "interestIncome", label: "Interest income (box 1)", type: "currency", required: true },
      { key: "earlyWithdrawalPenalty", label: "Early withdrawal penalty (box 2)", type: "currency" },
      { key: "interestOnUsTreasury", label: "Interest on U.S. savings bonds / Treasury (box 3)", type: "currency" },
      { key: "federalIncomeTaxWithheld", label: "Federal income tax withheld (box 4)", type: "currency" },
    ],
  },
  {
    code: "1098",
    title: "1098 — Mortgage Interest Statement",
    description: "Issued by the mortgage servicer.",
    fields: [
      { key: "lenderName", label: "Lender name", type: "text", required: true },
      { key: "lenderTin", label: "Lender TIN", type: "tin" },
      { key: "mortgageInterest", label: "Mortgage interest received (box 1)", type: "currency", required: true },
      { key: "outstandingPrincipal", label: "Outstanding mortgage principal (box 2)", type: "currency" },
      { key: "pointsPaid", label: "Points paid (box 6)", type: "currency" },
      { key: "propertyTax", label: "Property tax (box 10)", type: "currency" },
    ],
  },
  {
    code: "1040-summary",
    title: "1040 — Annual Summary (manual)",
    description: "High-level summary you fill from your full 1040. For tracking — does not compute liability.",
    fields: [
      { key: "filingStatus", label: "Filing status", type: "text" },
      { key: "totalIncome", label: "Total income (line 9)", type: "currency" },
      { key: "adjustedGrossIncome", label: "AGI (line 11)", type: "currency" },
      { key: "taxableIncome", label: "Taxable income (line 15)", type: "currency" },
      { key: "totalTax", label: "Total tax (line 24)", type: "currency" },
      { key: "totalPayments", label: "Total payments (line 33)", type: "currency" },
      { key: "refundOrOwed", label: "Refund (positive) or owed (negative)", type: "currency" },
    ],
  },
];

export function findFormDef(code: string): TaxFormDef | undefined {
  return TAX_FORMS.find((f) => f.code === code);
}
