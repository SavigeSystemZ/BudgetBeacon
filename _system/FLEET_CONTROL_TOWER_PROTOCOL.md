# Fleet Control Tower Protocol

Fleet control scripts:

- `bootstrap/emit-fleet-status.sh`
- `bootstrap/check-fleet-readiness.sh`

Required per-agent state fields:
- `agent_id`, `agent_type`, `role`, `lane`, `branch`, `write_scope`
- `lease_started_at`, `lease_expires_at`, `heartbeat_at`
- `status`, `blocked_by`, `last_validation`, `next_step`

Supported fleet id families:

- `cursor-01..N`
- `codex-01..N`
- `copilot-01..N`
- `windsurf-01..N`
- `claude-01..N`
- `gemini-01..N`
- `aider-01..N`
- `agentzero-01..N`

Readiness checks fail on expired leases, stale heartbeats, or overlapping write
scopes.
