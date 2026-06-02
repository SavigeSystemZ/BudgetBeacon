# Archetype Pack: finance-budgeting-app

## App purpose
Personal or team budgeting and finance tracking with high data integrity.
## Required docs
- PrecisionPolicy, AuditPolicy, PrivacyPolicy, RecoveryPolicy
## Required runtime surfaces
- ledger, reconciliation logic, reporting UI
## Recommended stack options
- fullstack app with relational DB
## Security/privacy posture
- strict access controls, encrypted sensitive data
## Installer expectations
- backup/restore and migration checks
## Port policy
- governed service ports, no default public DB
## Validation gates
- precision tests, reconciliation tests, strict validations
## UI/UX completion requirements
- clear balances, trend views, export controls
## Platform expectations
- web or desktop
## Fleet roles
- finance-domain-review, backend, QA
## Prompt-pack hooks
- release readiness and risk register standards
## Benchmark/test-app scenario
- Budget-style benchmark workload
## Anti-patterns
- floating-point money math, missing audit trails
