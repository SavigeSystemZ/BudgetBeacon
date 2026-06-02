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

- `_system/agent-state/active-agents.json` (derived index)
- `_system/agent-state/locks/<scope_hash>.lock.json` (per-scope mutex)
- `_system/agent-state/leases/<agent_id>.lease.json` (per-instance identity record)
- `_system/agent-state/heartbeats/<agent_id>.json`
- `_system/agent-state/lanes/<lane_id>.json`
- `_system/agent-state/conflicts/<ts>-conflict.md`
- `_system/agent-state/quarantine/<agent_id>/` (forensic snapshots of expired leases)
- `_system/agent-state/audit/<YYYY-MM>.jsonl` (append-only event log; S11)

The locks-vs-leases split is documented in `AGENT_LOCKING_AND_LEASES.md` and
`AGENT_INSTANCE_ISOLATION_POLICY.md`. Locks are per-scope mutexes; leases
are per-instance identity records that hold zero-or-more locks.

## Validation

- `bash bootstrap/check-agent-orchestration.sh TEMPLATE`
- `bash bootstrap/check-agent-locks.sh TEMPLATE`
- `bash bootstrap/check-agent-instance-isolation.sh TEMPLATE` (S3)
- `bash bootstrap/validate-system.sh TEMPLATE --strict`

## Instance-level rules

The fleet protocol above is the **coordination** layer. The per-instance
identity / lease / fencing layer is defined in
`AGENT_INSTANCE_ISOLATION_POLICY.md` and its machine-form
`agent-instance-policy.json`. New agents and validators MUST consult that
policy for naming regex, concurrency caps, lease TTL, heartbeat interval,
fencing-token semantics, and the locks-vs-leases directory split.

