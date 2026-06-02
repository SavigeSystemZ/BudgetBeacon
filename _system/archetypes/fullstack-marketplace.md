# Archetype Pack: fullstack-marketplace

## App purpose
Two-sided marketplace with catalog, accounts, transactions, and moderation.
## Required docs
- Roles, TrustPolicy, TransactionPolicy, DataModel, Security
## Required runtime surfaces
- web app, API, queue/workers, DB
## Recommended stack options
- Next.js + API + relational DB
## Security/privacy posture
- strict authz, anti-abuse controls, audit events
## Installer expectations
- migration-safe deploy and rollback plan
## Port policy
- governed multi-service port allocation
## Validation gates
- integration tests, transaction integrity, security scans
## UI/UX completion requirements
- role-specific workflows, abuse reporting, clear transaction states
## Platform expectations
- web + API, optional mobile clients
## Fleet roles
- backend-dev, frontend-dev, security-review, data-steward
## Prompt-pack hooks
- M17 + release readiness
## Benchmark/test-app scenario
- AIAST-Test-FullstackDB
## Anti-patterns
- weak fraud controls, missing consistency checks
