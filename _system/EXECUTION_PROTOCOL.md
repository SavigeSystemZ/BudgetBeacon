# Execution Protocol

This is the standard operating model for how agents should work inside the repo.

## Preflight

- Load the canonical docs (optionally read `_system/SYSTEM_ORCHESTRATION_GUIDE.md` first for a single map of surfaces, review order, and validation order).
- For **large or domain-shaping** user requests, reconcile against `_system/INSTRUCTION_DOMAIN_ALIGNMENT_PROTOCOL.md`, `_system/PROJECT_DOMAIN_MANIFEST.json`, and `_system/PROJECT_PROFILE.md` so you do not execute prompts meant for another product.
- Read the latest handoff state.
- Inspect the actual repo state before deciding anything.
- Separate confirmed repo facts from assumptions.
- Identify which working surfaces matter for the task: plan, design, architecture, research, testing, release, or risk.

## Task modes

- Implementation mode: change behavior with the smallest robust patch and run risk-matched validation.
- Debug or repair mode: reproduce, isolate, repair, prove, and document the failure.
- Review mode: prioritize correctness, regression, boundaries, tests, and security.
- Architecture mode: reason about seams, contracts, migrations, and long-term maintainability before changing code.
- Design mode: use the design framework and review playbooks to drive intentional UI decisions.
- Release mode: confirm build, install, launch, documentation, and risk posture.

## Tier S: Infinite Context (1M+ tokens)

When operating with Tier S capacity (e.g., Gemini 2.5 Pro):

- Perform whole-repo analysis before major changes.
- Cross-reference runtime code against the entire `_system/` layer to detect drift.
- Use multimodal inputs (screenshots/video) to verify UI/UX and layout fidelity.
- Use deep 'Chain of Thought' reasoning to plan complex multi-file refactors.
- Identify "leaky" abstractions that span multiple modules.

## Stage 1: Understand the problem

- Identify the exact objective.
- Confirm the smallest affected surface.
- Separate facts from assumptions.
- Decide whether the task is design, implementation, debug, review, or release work.
- Record or update assumptions in `_system/context/ASSUMPTIONS.md` when they materially affect the approach.

## Stage 2: Design the change

- Choose the smallest robust path.
- Preserve boundaries and existing contracts unless change is intentional.
- Split refactor-only work from behavior change when needed.
- Decide what validation will prove the change.
- Update `PLAN.md`, `DESIGN_NOTES.md`, `ARCHITECTURE_NOTES.md`, or `TEST_STRATEGY.md` when the task changes the operating picture.

## Stage 3: Implement

- Touch the fewest files possible.
- Keep the code explicit and production-grade.
- Add comments only when the logic would otherwise be expensive to parse.
- Avoid partial or placeholder implementations unless explicitly requested.
- Keep app runtime and `_system/` governance concerns separate.

## Stage 4: Verify

- Run the narrowest relevant checks first.
- Expand outward according to risk.
- For install, launch, packaging, migration, or operator-facing change, validate the real runtime path.
- After **large** implementation or refactor sessions, re-check that the app **launches and renders** (or API health) per `AGENT_INSTALLER_AND_HOST_VALIDATION_PROTOCOL.md` unless the change is purely non-runtime.
- Record command, scope, and result for meaningful verification.

## Stage 5: Record and hand off

Follow the requirements in `_system/HANDOFF_PROTOCOL.md`. At minimum:

- Update `WHERE_LEFT_OFF.md` with all required fields: session snapshot, last completed work, validation run (with command/result/scope), and next best step.
- Update `TODO.md` with completed and discovered items using priority signals (CRITICAL/HIGH/MEDIUM/LOW).
- Update `FIXME.md` with any newly discovered bugs or debt.
- Update `RISK_REGISTER.md` when delivery confidence changes.
- Update docs if architecture, contracts, workflow, design direction, or test intent changed.
- Update `CHANGELOG.md` and `RELEASE_NOTES.md` for user-visible or architectural changes.
- Update `_system/context/` when durable state shifted.
- Verify handoff quality: run `bootstrap/check-evidence-quality.sh` to confirm claims are grounded.

## Decision rules

- Ask questions only when a reasonable assumption would be risky.
- When blocked, reduce scope before escalating.
- When a task is too large, split into explicit step parts with clear validation.
- Do not confuse a plan with proof. Claims require evidence.
- When using **separate host terminals or tools** as auxiliaries, follow
  `_system/SUB_AGENT_HOST_DELEGATION.md` (disjoint write scopes, ≤2 concurrent auxiliaries preferred,
  primary owns merge and takeover if an auxiliary fails).
