# Assistant context coverage vs Dexie schema

The Beacon assistant’s **read-only** grounding is built from real IndexedDB data. This document maps **which tables** feed the system prompt and **which are intentionally omitted** (privacy, size, or redundancy).

## Loaded for every context build

| Dexie table(s) | Role in prompt |
|----------------|----------------|
| `incomeSources`, `bills`, `debts`, `savingsGoals`, `transactions`, `subscriptions`, `insuranceRecords` | `calculateBudgetSummary` — income, pressure, stash schedule, insurance roll-up |
| `transactions` | MTD expense rollup by category (`buildExpenseCategoryRollup`) |
| `creditSnapshots` | Latest score line (by `snapshotDate`) |
| `taxRecords`, `taxForms`, `documents`, `payeeRules` | **Count only** — lets the model cite that Tax Taxi, Vault, and import rules have data without emitting document contents |

Implementation: `collectAssistantPromptFacts` → `buildAssistantPromptFacts` → `formatAssistantSystemPrompt` in `src/modules/ai/`.

## Not currently in the system prompt

| Tables / data | Reason |
|---------------|--------|
| `households`, `persons` | Omit PII unless we add coarse counts later |
| `debtTransactions`, `taxTransactions` | Subordinate line items — would need summarization rules |
| `documents` blobs | Privacy + token cost; OCR output is committed to typed rows |
| `aiConfig` | Sensitive; assistant never echoes keys/endpoints |
| `chatMessages` | Conversation assembled separately (`BeaconChatbot` / `conversationWindow`) |
| `syncLogs` | Manual bridge only until M10 |

## Maintainer checklist when adding a Dexie store

1. Add the table to `fullDatabaseRwScope()` in `src/db/fullDatabaseScope.ts` if it persists user data (backup/wipe parity).
2. Decide whether it should appear in **`collectAssistantPromptFacts`** (prefer **counts or aggregates**, not raw records).
3. Update this file so the gap between schema and grounding stays visible.

_Last updated 2026-05-03._
