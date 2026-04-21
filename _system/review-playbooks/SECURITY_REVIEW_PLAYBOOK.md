# Security Review Playbook

## Review inputs

- `_system/SECURITY_REDACTION_AND_AUDIT.md`
- `_system/MCP_CONFIG.md`
- touched auth, data, logging, export, or tooling surfaces

## Review for

- secret leakage
- missing authorization or validation seams
- privilege expansion without policy
- unsafe exports or logs
- overbroad MCP or tooling permissions

## Must-fix findings

- secrets in repo-tracked files
- sensitive operations without boundary checks
- MCP or tooling scope wider than necessary
- logging or export paths that expose sensitive user or operator data

## Output format

- critical issues
- exposure risks
- remediation notes
- follow-up hardening work if the issue is not fully closed
