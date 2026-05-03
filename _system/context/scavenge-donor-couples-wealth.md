# Scavenge note: CouplesWealth (sibling read-only donor)

**Donor path:** `~/.MyAppZ/CouplesWealth`  
**Target:** Budget Beacon runtime under `src/` only.  
**Constraint:** No writes to the donor repo; patterns were reviewed and reimplemented here.

## What was reviewed

- `src/components/charts/IncomeExpenseChart.jsx` — monthly income vs expenses bar chart (Recharts).
- `src/components/dashboard/BudgetHealthScore.jsx` — circular score + savings framing.
- `src/components/utils/transactionHelpers.jsx` — split-aware rollups (not applicable 1:1; logic distilled for our positive-amount schema).
- `src/components/dashboard/StatCard.jsx` — metric presentation (we already had `MetricCard`; extended with icons only).

## What landed in Budget Beacon

| Donor idea | Beacon implementation |
|------------|-------------------------|
| Income vs expense monthly bars | `src/components/charts/IncomeExpenseBarChart.tsx` + `buildMonthlyIncomeExpenseSeries` in `src/modules/ledger/transactionDisplay.ts` |
| Budget health / savings target | `src/components/dashboard/BudgetHealthScoreCard.tsx` (Stash rate vs 20% target, theme-aligned) |
| Transaction amount display helpers | `formatLedgerAmountDisplay`, `rollupCategoryTotals` in `transactionDisplay.ts`; ledger list uses formatter |
| Tests | `src/modules/ledger/transactionDisplay.test.ts` |

## Intentionally not copied

- Governed HTTP API client, Stripe, server-backed auth flows.
- Split-transaction model (no matching Dexie tables yet).
- Full shadcn component pack parity (would bloat deps vs current Tailwind 4 stack).

## Follow-up (optional)

- [x] **2026-05-02:** `buildExpenseCategoryRollup` + `ExpenseCategoryRollup` wired into **Reports → Monthly** and **Mission Control** (MTD expense by category).
- [x] **2026-05-02 (b):** Ledger **top-3 MTD** sidebar; CSV **`expenseCategoriesMtd`**; **`buildAssistantContext`** insurance + MTD category facts for the assistant.
- [x] **2026-05-02 (c):** Dashboard **`MtdCategoryDonut`** (same rollup); Vitest coverage for **`buildCsvForEntity`** MTD export and **`buildAssistantContext`** prompt lines.
- [x] **2026-05-02 (d):** Assistant context split — **`assistantContextFacts`** pure layer + **`TEST_STRATEGY`** hazard note (fake timers vs Dexie).
- If splits are added to the schema, extend `transactionDisplay` with donor-style effective-line expansion.
