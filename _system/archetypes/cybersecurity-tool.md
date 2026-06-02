# Archetype Pack: cybersecurity-tool

## App purpose
Authorized security testing and analysis tool with strict scope controls.
## Required docs
- LegalScope, AuthorizationModel, ThreatModel, AuditPolicy
## Required runtime surfaces
- scope manager, evidence logger, controlled execution engine
## Recommended stack options
- Python CLI/API with secure storage
## Security/privacy posture
- explicit authorization gates, non-bypassable logging
## Installer expectations
- privileged operations are opt-in and documented
## Port policy
- loopback-first, no broad service exposure
## Validation gates
- scope checks, audit trace checks, strict system checks
## UI/UX completion requirements
- clear permission prompts and operation visibility
## Platform expectations
- CLI-first with optional UI
## Fleet roles
- security-steward, compliance-review, validation-steward
## Prompt-pack hooks
- authorized security research mode
## Benchmark/test-app scenario
- AIAST-Test-CyberTool
## Anti-patterns
- unauthorized operation defaults, missing legal scope proofs
