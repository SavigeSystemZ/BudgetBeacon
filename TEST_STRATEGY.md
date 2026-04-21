# Test Strategy

Use this file to define the repo's confidence model, validation lanes, and known coverage gaps.

## Confidence model

- required confidence for local changes: per `_system/VALIDATION_GATES.md` Tier 1–2.
- required confidence for risky changes: Tier 3–4; install/launch/CI work requires real runtime or workflow verification.
- required confidence for release candidates: Tier 5; all relevant gates green or documented degradation.

## Validation lanes

- format or lint: from `_system/PROJECT_PROFILE.md`
- typecheck: from `_system/PROJECT_PROFILE.md`
- unit tests: from `_system/PROJECT_PROFILE.md`
- integration tests: when the product exposes integration surfaces
- end-to-end or smoke: after large refactors or UI/routing changes (`AGENT_INSTALLER_AND_HOST_VALIDATION_PROTOCOL.md`)
- build or packaging checks: when `packaging/` or `distribution/` changes
- security or policy checks: `bootstrap/scan-security.sh`, supply-chain checks as applicable

## Coverage expectations

- critical flows that must be proven: defined per product in `PRODUCT_BRIEF.md` or architecture notes
- areas allowed to rely on lighter validation: docs-only or `_system/`-only edits (still run instruction/conflict checks)
- expected evidence for high-risk changes: recorded in `WHERE_LEFT_OFF.md` per `_system/HANDOFF_PROTOCOL.md`

## Known gaps

- Master template does not run product tests; downstream repos must fill this section with product-specific coverage gaps.
- Confirm the seeded validation lanes against the first real repo-local run and record any missing coverage explicitly.

## Usage rules

- Keep this aligned with `RISK_REGISTER.md` and `RELEASE_NOTES.md`.
- Record what confidence is required, not just what happens to exist today.

---

*Template baseline reviewed: 2026-04-06.*
