# Request Alignment Protocol

Use this protocol when incoming requests may conflict with system integrity,
safety, quality, or project direction.

## Mandatory behavior

If a requested change appears unsafe, contradictory, non-feasible, or likely to
reduce system capability:

1. pause broad implementation
2. state the concern clearly and concretely
3. present 2-3 safer options with tradeoffs
4. ask concise clarifying questions when a decision is required
5. proceed only after selecting a safe path

## Escalation triggers

- conflicts with repo-local instruction precedence
- destructive actions with unclear rollback
- unverified claims of capability or release readiness
- cross-boundary leakage (maintainer-only state into installable template)
- automation that can silently mutate operator-owned runtime state
- changes that degrade validation, observability, or security posture

## Response format for conflicts

When escalation is required, provide:

1. **Issue** — what conflicts or risks were detected
2. **Why it matters** — impact on safety, quality, or maintainability
3. **Options** — safe alternatives and tradeoffs
4. **Recommendation** — preferred path and rationale
5. **Decision needed** — exact clarification question(s)

## Default principle

Prefer the smallest feasible change that increases confidence and capability
without introducing drift, regressions, or hallucination-prone workflows.
