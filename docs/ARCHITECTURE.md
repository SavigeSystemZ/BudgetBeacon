# Architecture

## Style
Local-first modular monolith.

## Stack
- React + TypeScript + Vite
- Tailwind CSS v4 + shadcn/ui
- Recharts (for data visualization)
- Dexie/IndexedDB (for persistence)
- React Hook Form + Zod (for validated forms)
- Vitest (for budget engine tests)

## Module Map
- `src/main.tsx`, `App.tsx`
- `routes/` (Dashboard, Income, PayPath, StashMap, Credit, Reports, Settings)
- `components/` (Layout, UI, Cards, Charts, Forms, Empty States)
- `modules/` (Household, Income, PayPath, StashMap, Credit, BudgetEngine, Reports)
- `db/` (Dexie instance, Seeding)
- `lib/` (Formatting, Validation)

## Data Flow
1. User enters data through Zod-validated forms.
2. Data normalizes into typed entities.
3. Data persists locally to IndexedDB via Dexie.
4. The pure `budget-engine` reads normalized data.
5. The Dashboard recalculates and displays the summary and deterministic recommendations.

## Critical Architecture Rule
- Budget math MUST live exclusively in `modules/budget-engine/`.
- UI components MUST NOT duplicate calculation logic.