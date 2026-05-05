# Validation And Release Pattern

## Use when

- a change touches install, launch, packaging, runtime health, or release posture
- the repo needs stronger signoff discipline
- validation evidence is weaker than the claims being made

## Primary donors

- curated-donor

## What to emulate

- narrow-to-broad validation based on change risk
- executable runtime checks for install and packaging changes
- honest degraded-mode reporting instead of overclaiming green status
- release notes that distinguish source-template confidence from installed-runtime confidence

## What not to inherit

- donor-specific runtime commands or packaging targets unless the target repo truly has them
- release confidence claims without command evidence
- static-only validation for runtime changes

## Adoption checklist

1. Record exactly which commands were run.
2. Separate source-template proof from installed-repo proof.
3. Keep known gaps in `FIXME.md`, `RISK_REGISTER.md`, or `TEST_STRATEGY.md`.
4. Do not call a release ready unless the touched surface has been exercised.
