# Data Model

## Overview
The application uses a local-first IndexedDB schema managed by Dexie.js.

## Core Entities
- **Budgets/Categories**: Define monthly spending limits.
- **Transactions**: Individual spending records associated with a category.
- **Rollups**: Derived views calculating month-to-date spending vs budget.
