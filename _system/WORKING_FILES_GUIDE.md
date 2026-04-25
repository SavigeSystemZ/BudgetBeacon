# Working Files Guide

This document explains the role of the repo-facing planning, context, design, testing, and handoff files.

## Core rule

The master template may include app-shaped working files, but the master template itself must remain app-agnostic. Once installed into a real repo, these files become the local source of truth for that repo.

In the AIAST source repo, maintainer-only planning, research, handoff, and future system-design state belongs outside the installable tree in the master-repo-only meta workspace.

**See also:** `_system/SYSTEM_ORCHESTRATION_GUIDE.md` — how these files fit tiered load order (`LOAD_ORDER.md`), handoff discipline, and validation.

## Top-level working files

- `PRODUCT_BRIEF.md` — product frame, quality bar, recommended build shape, and chosen build shape
- `TODO.md` — active queue and discovered follow-up work
- `FIXME.md` — unresolved bugs, debt, and blockers
- `WHERE_LEFT_OFF.md` — next-agent resume packet
- `PLAN.md` — active execution plan for the current milestone
- `ROADMAP.md` — medium-term sequencing and milestone ordering
- `DESIGN_NOTES.md` — durable design direction and design-review memory
- `ARCHITECTURE_NOTES.md` — durable architecture direction and structural review memory
- `RESEARCH_NOTES.md` — findings, experiments, benchmarks, and evidence
- `TEST_STRATEGY.md` — expected confidence model and known coverage gaps
- `RISK_REGISTER.md` — active delivery, quality, security, and release risks
- `RELEASE_NOTES.md` — current milestone or release-facing summary
- `CHANGELOG.md` — durable change history

## Durable context files

- `context/CURRENT_STATUS.md` — current operating reality
- `context/DECISIONS.md` — durable decisions and why they were made
- `context/MEMORY.md` — stable conventions, preferences, and constraints
- `context/ARCHITECTURAL_INVARIANTS.md` — rules that should almost never change
- `context/ASSUMPTIONS.md` — active assumptions that still need confirmation
- `context/INTEGRATION_SURFACES.md` — external systems, contracts, and dependencies that affect implementation
- `context/OPEN_QUESTIONS.md` — unresolved decisions that materially affect work
- `context/QUALITY_DEBT.md` — known quality gaps that are real but not currently blocking

## Update guidance

- Update the smallest set of working files needed to leave a truthful operating picture.
- If the task changed product direction, user value framing, or starter-blueprint choice, update `PRODUCT_BRIEF.md`.
- If a starter blueprint was explicitly applied, make sure the blueprint-projected operating surfaces remain aligned: `PLAN.md`, `ROADMAP.md`, `DESIGN_NOTES.md`, `TEST_STRATEGY.md`, `RISK_REGISTER.md`, `ARCHITECTURE_NOTES.md`, `TODO.md`, `WHERE_LEFT_OFF.md`, and `RELEASE_NOTES.md`.
- If the task changed delegation rules, role ownership, or multi-agent execution shape, update `_system/AGENT_ROLE_CATALOG.md` and `_system/MULTI_AGENT_COORDINATION.md`.
- If the task changed workspace authority, project-scope enforcement, redirect shim strategy, session environment reporting, scavenging permissions, or orphan snapshot rules, update the corresponding `_system/*_PROTOCOL.md` contract files in the same pass.
- If the task changed design direction, update `DESIGN_NOTES.md`.
- If the task changed architecture or boundaries, update `ARCHITECTURE_NOTES.md`.
- If the task changed confidence, coverage, or release posture, update `TEST_STRATEGY.md`, `RISK_REGISTER.md`, or `RELEASE_NOTES.md`.
- If the task produced durable facts or uncovered uncertainty, update the relevant file in `context/`.

## Golden examples

Use these only as quality-bar references, not donor truth:

- `_system/golden-examples/working-files/PROJECT_PROFILE_EXAMPLE.md`
- `_system/golden-examples/working-files/PLAN_EXAMPLE.md`
- `_system/golden-examples/working-files/WHERE_LEFT_OFF_EXAMPLE.md`

The examples show the expected level of specificity, grounding, and handoff quality. They must be rewritten into repo-local truth after install.

## Anti-patterns

- Do not turn these files into noisy chat transcripts.
- Do not duplicate the same facts across every file.
- Do not leave app-specific content in the master template source.
- Do not store AIAST-maintainer working state in these installable files when the work only applies to the master source repo.
