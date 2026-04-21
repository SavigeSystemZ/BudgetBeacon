# Plan

Use this file as the current implementation plan for the active repo milestone or problem set.

## Objective

- Current target outcome: define and deliver the first real Budget Beacon milestone around budget setup, transaction capture, and month-to-date budget visibility.
- Why it matters now: the repo now has the operating system installed, but the next pass needs a concrete budgeting slice so the product shape and validation baseline become real.
- Deadline or forcing function: note if one exists.

## Success criteria

- User or operator outcome: a user can create a starter budget, record a small set of transactions, and understand remaining budget by category.
- Technical outcome: the repo has a chosen runtime shape, initial code roots, and at least one real validation lane for budgeting rules.
- Design or product-quality outcome: the first visible surface feels like a trustworthy finance product rather than a generic scaffold.

## Scope lock

- In scope: tasks actively tracked in `TODO.md` for this phase.
- Out of scope: deferred items unless promoted from `FIXME.md` or `RISK_REGISTER.md`.
- Dependencies: repo inspection, `PRODUCT_BRIEF.md`, available toolchain, and at least one real validation command.
- Known unknowns: platform choice, persistence model, transaction import scope, deployment assumptions, and missing environment details.

## Assumptions

- Record only assumptions that materially affect current execution.

## Execution slices

1. Choose the initial delivery surface and starter blueprint, then define code roots and validation entrypoints.
2. Implement the first budgeting slice: budget categories, transaction capture or import stub, month-to-date rollups, and a basic status view.
3. Add validation for budget calculations and state transitions, then close out with updated handoff evidence.

## Validation plan

- Commands to run: per `_system/PROJECT_PROFILE.md`.
- Evidence to capture: command, scope, pass/fail in `WHERE_LEFT_OFF.md`.
- Stop conditions: per `_system/FAILURE_MODES_AND_RECOVERY.md`.
- Release-blocking checks: per `_system/RELEASE_READINESS_PROTOCOL.md` when shipping.

---

*Template baseline reviewed: 2026-04-06 — replace placeholders when this file is copied into a live product repo.*
