# Data Model & Storage

All data is stored locally via IndexedDB using Dexie. Entities are fully typed in TypeScript and validated with Zod before persistence.

## Entities
1. **Household:** `{ id, name, currency, createdAt, updatedAt }`
2. **Person:** `{ id, householdId, name, role, colorTag }`
3. **IncomeSource:** `{ id, householdId, label, amount, frequency, customMonthlyAmount, isActive }`
4. **Bill (Pay Path):** `{ id, householdId, label, category, amount, frequency, dueDay, autopay, isEssential }`
5. **Debt (Pay Path):** `{ id, householdId, label, balance, apr, minimumPayment, dueDay, category, priority }`
6. **SavingsGoal (Stash Map):** `{ id, householdId, label, targetAmount, currentAmount, monthlyContribution, deadline, priority, category }`
7. **CreditSnapshot:** `{ id, householdId, score, bureauOrSource, model, snapshotDate, notes }`

## Storage Schema (Dexie)
Database versions should be strictly managed to allow migrations.
The core database `db.ts` defines these typed tables for querying and subscription.