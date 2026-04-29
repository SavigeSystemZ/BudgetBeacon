import type { PayeeRule } from "../../db/db";

/**
 * Apply user-defined payee rules to a draft transaction. First matching rule
 * wins (order is the order rules were stored). When `payeeOverride` is set,
 * the payee is replaced; when `category` is set, the category is replaced.
 *
 * Matching is done against a canonical lowercased payee — same normalization
 * the dedupe key uses, so rules generalize across capitalization, punctuation,
 * and surrounding whitespace.
 */

export interface PayeeMatchable {
  payee?: string;
  category?: string;
}

export interface ApplyResult<T extends PayeeMatchable> {
  draft: T;
  matchedRuleId: string | null;
}

const PUNCT = /[^a-z0-9 ]/g;

export function normalizePayeeKey(raw: string | undefined): string {
  if (!raw) return "";
  return raw.toLowerCase().replace(PUNCT, " ").replace(/\s+/g, " ").trim();
}

export function applyPayeeRules<T extends PayeeMatchable>(draft: T, rules: PayeeRule[]): ApplyResult<T> {
  const key = normalizePayeeKey(draft.payee);
  if (!key) return { draft, matchedRuleId: null };

  for (const rule of rules) {
    const pat = (rule.pattern || "").toLowerCase().trim();
    if (!pat) continue;
    const hit = rule.matchType === "exact" ? key === pat : key.includes(pat);
    if (!hit) continue;
    return {
      draft: {
        ...draft,
        payee: rule.payeeOverride?.trim() || draft.payee,
        category: rule.category?.trim() || draft.category,
      },
      matchedRuleId: rule.id,
    };
  }

  return { draft, matchedRuleId: null };
}

export function applyPayeeRulesToAll<T extends PayeeMatchable>(
  drafts: T[],
  rules: PayeeRule[],
): Array<ApplyResult<T>> {
  return drafts.map((d) => applyPayeeRules(d, rules));
}
