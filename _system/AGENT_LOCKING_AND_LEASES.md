# Agent Locking And Leases

Use leases to enforce single-writer-per-scope while allowing parallel
non-overlapping work.

## Lease Lifecycle

1. Claim: `bootstrap/agent-lock.sh`.
2. Maintain: `bootstrap/agent-heartbeat.sh`.
3. Release: `bootstrap/agent-unlock.sh`.
4. Reclaim expired lease: `bootstrap/agent-reclaim-lock.sh`.
5. Validate: `bootstrap/check-agent-locks.sh`.

## Lock File Shape

```json
{
  "scope": "src/features/billing/**",
  "owner_agent_id": "codex-02",
  "owner_role": "implementation-worker",
  "lease_started_at": "2026-05-06T11:29:00Z",
  "lease_expires_at": "2026-05-06T11:59:00Z",
  "checkpoint": "_system/checkpoints/LATEST.json",
  "notes": "billing vertical slice"
}
```

## Reclaim Policy

- Reclaim only expired leases.
- Record reclaim rationale in `_system/agent-state/conflicts/`.
- Do not reclaim active leases with fresh heartbeat unless operator-approved.

