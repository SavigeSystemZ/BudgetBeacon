# Archetype Pack: background-check-or-osint-app

## App purpose
Perform authorized intelligence/background workflows with strict legal controls.
## Required docs
- LegalScope, AuthorizationWorkflow, DataUsePolicy, AuditPolicy
## Required runtime surfaces
- query workflow, authorization gate, evidence ledger
## Recommended stack options
- API + analyst UI + audit backend
## Security/privacy posture
- least-data collection, explicit purpose limitation
## Installer expectations
- legal mode and authorization checks
## Port policy
- controlled endpoints with access restrictions
## Validation gates
- authorization checks, audit completeness, strict validations
## UI/UX completion requirements
- explicit rationale and scope states
## Platform expectations
- web/API with controlled access
## Fleet roles
- legal-review, analyst, validation-steward
## Prompt-pack hooks
- authorized research and evidence policies
## Benchmark/test-app scenario
- AIAST-Test-MetasystemReviewer
## Anti-patterns
- scraping without scope authorization, hidden data provenance
