# Archetype Pack: metasystem-reviewer-app

## App purpose
Review, score, and validate meta-system contract quality across repos.
## Required docs
- ReviewProtocol, ScoringModel, EvidencePolicy, PromotionGates
## Required runtime surfaces
- validator runner, scoring engine, report sink
## Recommended stack options
- Python CLI + markdown/json reporting
## Security/privacy posture
- read-only by default, no secret ingestion
## Installer expectations
- validator dependency checks and reproducible runs
## Port policy
- no network requirement by default
## Validation gates
- strict contract checks, score reproducibility tests
## UI/UX completion requirements
- transparent findings and remediation steps
## Platform expectations
- CLI-first
## Fleet roles
- reviewer, validator, release-steward
## Prompt-pack hooks
- M17 app-builder and review playbooks
## Benchmark/test-app scenario
- AIAST-Test-MetasystemReviewer
## Anti-patterns
- undocumented scoring weights, unverifiable claims
