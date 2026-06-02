# Archetype Pack: data-dashboard

## App purpose
Interactive dashboard for analytics, reporting, and operational visibility.
## Required docs
- DataModel, MetricsCatalog, AccessPolicy, RetentionPolicy
## Required runtime surfaces
- ingest pipeline, query layer, dashboard UI
## Recommended stack options
- Python API + JS frontend + analytics DB
## Security/privacy posture
- row-level access controls, PII handling rules
## Installer expectations
- data source config and smoke checks
## Port policy
- governed service ports; no default public exposure
## Validation gates
- data quality checks, dashboard render smoke, strict validations
## UI/UX completion requirements
- filtering, export, empty/error states, accessibility
## Platform expectations
- web-first
## Fleet roles
- data-engineer, frontend, QA
## Prompt-pack hooks
- benchmark + release readiness packs
## Benchmark/test-app scenario
- AIAST-Test-EvidenceReporting
## Anti-patterns
- unvalidated metrics, missing lineage documentation
