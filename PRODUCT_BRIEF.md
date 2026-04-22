# Product Brief

Use this file to capture the product idea, intended user value, and chosen build shape for this repo.

## Product frame

- Product name: Budget Beacon
- Product category: Personal budgeting and spending-awareness app
- One-line summary: Build Budget Beacon, a budgeting app that helps people track spending against planned monthly budgets and notice budget pressure early.
- Why it should exist: capture the user pain, operator leverage, or market opportunity this app resolves
- Primary users: Individuals and households managing everyday budgets
- Primary workflows: Set budget categories and monthly targets; capture or import transactions; review month-to-date spend vs budget; inspect remaining budget and overspending risk
- Success indicators: Users can create a budget, record realistic transactions, and understand current budget status from trustworthy totals and category rollups
- Non-goals: Tax preparation, investment advice, or multi-entity accounting in the first phase

## Experience bar

- Visual direction: Calm, polished, high-signal finance UI with intentional hierarchy
- Interaction bar: Quick budget review, clear transaction flows, and obvious state transitions
- Performance bar: Core budget status and transaction views should feel immediate on normal datasets
- Reliability bar: clear degraded states, explicit error handling, and no fake capability claims
- Trust and safety bar: security-conscious defaults, honest validation claims, and explicit handling of risky actions

## Build shape

- Recommended starter blueprint: REACT_VITE_TYPESCRIPT - React Vite TypeScript Blueprint
- Recommendation confidence: high
- Recommendation rationale: Best fit: REACT_VITE_TYPESCRIPT - React Vite TypeScript Blueprint. Signals: React dependency detected.; Vite config detected.; Product framing points to an interactive frontend surface.. Top alternatives: STATIC_FRONTEND (2).
- Selected starter blueprint: not yet selected
- Why this blueprint fits: choose a starter blueprint after the product frame and delivery surfaces are clearer
- Planned repo shape: decide after selecting a starter blueprint
- First milestone: prove one end-to-end user-facing or operator-facing slice with real validation
- Initial validation focus: confirm one real build, launch, test, or smoke path early and keep it passing
- Next decision gates: starter blueprint, persistence model, deployment targets, packaging expectations, and AI scope

## Usage rules

- Keep this aligned with `_system/PROJECT_PROFILE.md`, `PLAN.md`, `ROADMAP.md`, `DESIGN_NOTES.md`, and `ARCHITECTURE_NOTES.md`.
- If the repo is greenfield, use `bootstrap/recommend-starter-blueprint.sh` first, then use `bootstrap/apply-starter-blueprint.sh` to stamp the explicitly chosen starter blueprint into the first operating surfaces.
- Keep this factual and product-specific; do not turn it into vague aspiration or marketing filler.
