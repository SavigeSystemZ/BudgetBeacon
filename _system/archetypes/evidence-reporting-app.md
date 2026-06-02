# Archetype Pack: evidence-reporting-app

## App purpose
Capture, normalize, and publish auditable evidence and status reports.
## Required docs
- EvidencePolicy, RetentionPolicy, ReportSchema
## Required runtime surfaces
- event recorder, report generator, export channel
## Recommended stack options
- Python service + markdown/json emitters
## Security/privacy posture
- append-only event policy, redacted outputs
## Installer expectations
- report path and permissions checks
## Port policy
- optional loopback API only
## Validation gates
- schema validation, report generation smoke, strict checks
## UI/UX completion requirements
- traceability from claim to evidence
## Platform expectations
- CLI/API, optional web dashboard
## Fleet roles
- evidence-steward, reviewer
## Prompt-pack hooks
- provenance and evidence contracts
## Benchmark/test-app scenario
- AIAST-Test-EvidenceReporting
## Anti-patterns
- mutable audit history, unstructured unverifiable reporting
