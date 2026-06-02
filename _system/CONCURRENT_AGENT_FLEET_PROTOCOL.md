# Concurrent Agent Fleet Protocol

This protocol extends the baseline multi-agent model to support high-concurrency
operation with deterministic ownership and safety.

## Core Rules

- Many active agents are allowed.
- Only one active writer lease per file/scope.
- Validators and reviewers are read-only unless explicitly promoted.
- Each active agent must have a unique instance ID (for example `codex-01`).
- Heartbeats are required for long-running sessions.
- Stale leases may be reclaimed by steward role after timeout.

## Required Identity Fields

- `agent_id`
- `agent_type`
- `role`
- `lane`
- `branch`
- `write_scope`
- `lease_started_at`
- `lease_expires_at`
- `heartbeat_at`

## State Surfaces

- `_system/agent-state/active-agents.json`
- `_system/agent-state/locks/*.lock.json`
- `_system/agent-state/heartbeats/*.json`
- `_system/agent-state/lanes/*.json`
- `_system/agent-state/conflicts/*.md`

## Validation

- `bash bootstrap/check-agent-orchestration.sh TEMPLATE`
- `bash bootstrap/check-agent-locks.sh TEMPLATE`
- `bash bootstrap/validate-system.sh TEMPLATE --strict`

