# Fleet Control Tower Protocol

Fleet control scripts:

- `bootstrap/emit-fleet-status.sh`
- `bootstrap/check-fleet-readiness.sh`

Required per-agent state fields:
- `agent_id`, `agent_type`, `role`, `lane`, `branch`, `write_scope`
- `lease_started_at`, `lease_expires_at`, `heartbeat_at`
- `status`, `blocked_by`, `last_validation`, `next_step`

Readiness checks fail on expired leases, stale heartbeats, or overlapping write
scopes.
