# Archetype Pack: home-property-management-app

## App purpose
Manage property/home operations, maintenance, and records.
## Required docs
- DataPolicy, AccessPolicy, NotificationPolicy, BackupPlan
## Required runtime surfaces
- property records, task scheduler, notification system
## Recommended stack options
- web + mobile companion
## Security/privacy posture
- private household data protection and role-based access
## Installer expectations
- notification and backup setup verification
## Port policy
- local-safe defaults; governed remote access
## Validation gates
- schedule integrity, notification smoke, strict checks
## UI/UX completion requirements
- clear task lifecycle and document attachments
## Platform expectations
- web/mobile hybrid
## Fleet roles
- app-dev, mobile-dev, QA
## Prompt-pack hooks
- app-builder orchestration and delivery gates
## Benchmark/test-app scenario
- home-ops scenario workload
## Anti-patterns
- missing backup support, unclear data ownership
