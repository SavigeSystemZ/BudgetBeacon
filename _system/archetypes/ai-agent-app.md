# Archetype Pack: ai-agent-app

## App purpose
Agent-driven application with governed prompts, tool use, and fallback behavior.
## Required docs
- ModelPolicy, PromptSafety, ToolingPolicy, FallbackPolicy
## Required runtime surfaces
- orchestrator, model adapter, audit log, redaction layer
## Recommended stack options
- Python service + pluggable model backends
## Security/privacy posture
- no secrets in prompts, scoped tool permissions, audit traces
## Installer expectations
- provider config checks and offline fallback behavior
## Port policy
- governed API endpoints, loopback defaults when local
## Validation gates
- prompt redaction tests, failure-handling tests, strict validations
## UI/UX completion requirements
- explicit model-status and fallback transparency
## Platform expectations
- API-first, optional web/CLI clients
## Fleet roles
- agent-orchestrator, safety-review, validation-steward
## Prompt-pack hooks
- M17 + AI rules
## Benchmark/test-app scenario
- AIAST-Test-AIAgentApp
## Anti-patterns
- unbounded tool actions, hidden fallback failures
