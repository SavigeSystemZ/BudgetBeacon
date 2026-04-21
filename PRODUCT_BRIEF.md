# Product Brief

Use this file to capture the product idea, intended user value, and chosen build shape for this repo.

## Product frame

- Product name: Budget Beacon
- Product category: personal budgeting and spending-awareness app
- One-line summary: Budget Beacon helps people plan monthly budgets, capture spending, and see budget pressure before they overspend.
- Why it should exist: many people only notice category overspend after the money is already gone; the first product slice should make day-to-day budget status visible, trustworthy, and easy to act on.
- Primary users: individuals and households who want a clear view of budget targets, transaction activity, and remaining spend room.
- Primary workflows: create budget categories and monthly targets; capture or import transactions and assign categories; review month-to-date spending vs budget; surface remaining budget and overspending risk.
- Success indicators: a new user can set up a starter budget, record realistic transactions, and understand current category-level budget status without outside help.
- Non-goals: tax preparation, investment management, multi-entity bookkeeping, or speculative AI-generated financial advice.

## Experience bar

- Visual direction: calm, high-clarity finance UI with strong hierarchy, readable numbers, and trust-building restraint instead of dashboard clutter.
- Interaction bar: fast budget review and low-friction transaction capture on both desktop and mobile-sized layouts.
- Performance bar: dashboard summaries and transaction flows should feel immediate on a normal personal-finance dataset.
- Reliability bar: totals, category rollups, remaining-budget indicators, and period summaries must stay internally consistent and explainable.
- Trust and safety bar: treat financial data as sensitive, avoid invented balances or sync claims, and make any risky or destructive action explicit.

## Build shape

- Recommended starter blueprint: manual review required
- Recommendation confidence: low
- Recommendation rationale: No single starter blueprint is dominant yet. Current signals are too weak or too generic. Refine PRODUCT_BRIEF.md or add real runtime signals, then review the recommendation again.
- Selected starter blueprint: not yet selected
- Why this blueprint fits: the product clearly needs a user-facing budgeting surface and durable domain state, but the delivery surface is still open enough that forcing a blueprint now would be premature.
- Planned repo shape: choose a runtime shape that cleanly models budgets, categories, transactions, rollups, and reporting, then keep packaging and AI scaffolds aligned to that choice.
- First milestone: prove budget setup, transaction capture, category assignment, and month-to-date budget status in one end-to-end slice with real validation.
- Initial validation focus: establish one real launch path and one real automated lane that checks budget calculations and transaction/category state transitions.
- Next decision gates: starter blueprint, runtime surface (web, desktop, mobile, or hybrid), persistence model, import strategy, deployment targets, packaging expectations, and AI scope.

## Usage rules

- Keep this aligned with `_system/PROJECT_PROFILE.md`, `PLAN.md`, `ROADMAP.md`, `DESIGN_NOTES.md`, and `ARCHITECTURE_NOTES.md`.
- If the repo is greenfield, use `bootstrap/recommend-starter-blueprint.sh` first, then use `bootstrap/apply-starter-blueprint.sh` to stamp the explicitly chosen starter blueprint into the first operating surfaces.
- Keep this factual and product-specific; do not turn it into vague aspiration or marketing filler.
