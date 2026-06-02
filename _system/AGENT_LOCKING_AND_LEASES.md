# Agent Locking And Leases

Use leases to enforce single-writer-per-scope while allowing parallel
non-overlapping work.

This doc covers the **scope lock** atom. The instance identity layer that
owns these locks is in `AGENT_INSTANCE_ISOLATION_POLICY.md`. Together they
form AIAST's concurrency control. Machine-form policy:
`_system/agent-instance-policy.json`.

## Locks vs leases — terminology

`_system/agent-state/` ships two directories that previously had overlapping
semantics. They are now distinct:

| Directory | What it stores | Granularity |
|---|---|---|
| `locks/<scope_hash>.lock.json` | **Per-scope mutex.** Records who currently owns write access to a glob/path. | one per active scope |
| `leases/<agent_id>.lease.json` | **Per-instance identity record.** Holds agent identity, role, lane, branch, the set of scope locks it currently claims, and the fencing token. | one per active instance |

An active agent has exactly one lease and zero-or-more locks. Both are
created during claim and removed during release. See
`AGENT_INSTANCE_ISOLATION_POLICY.md` for the full lease record shape.

## Lease Lifecycle

1. Claim: `bootstrap/agent-lock.sh` (legacy single-scope) or
   `bootstrap/init-agent-instance.sh` (S3 multi-scope claim with fencing).
2. Maintain: `bootstrap/agent-heartbeat.sh`.
3. Release: `bootstrap/agent-unlock.sh`.
4. Reclaim expired lease: `bootstrap/agent-reclaim-lock.sh` (legacy) or
   `bootstrap/reap-stale-leases.sh` (S3 reaper → quarantine).
5. Validate: `bootstrap/check-agent-locks.sh` and
   `bootstrap/check-agent-instance-isolation.sh` (S3).

## Lock File Shape

```json
{
  "scope": "src/features/billing/**",
  "scope_hash": "sha256:...",
  "owner_agent_id": "codex-02",
  "owner_role": "implementation-worker",
  "lease_started_at": "2026-05-06T11:29:00Z",
  "lease_expires_at": "2026-05-06T11:59:00Z",
  "fencing_token": 1715472017000003,
  "checkpoint": "_system/checkpoints/LATEST.json",
  "notes": "billing vertical slice"
}
```

`fencing_token` is the monotonic token issued at lease-claim time.
Validators reject writes that arrive with a `fencing_token` strictly less
than the current max recorded for that scope — see "Fencing Tokens" below.

## Reclaim Policy

- Reclaim only expired leases (`now >= lease_expires_at` plus one grace
  cycle of `heartbeat_interval_seconds`).
- Record reclaim rationale in `_system/agent-state/conflicts/`.
- Do not reclaim active leases with fresh heartbeat unless operator-approved.
- Default action on reclaim: **quarantine** the lease + lock pair into
  `_system/agent-state/quarantine/<agent_id>/`. Forensic state is preserved
  for operator review; the slot is freed. See
  `AGENT_INSTANCE_ISOLATION_POLICY.md#lease-lifecycle`.

## Fencing Tokens

Time-based expiry alone is not safe: a paused writer can resume past TTL
and emit writes the system no longer authorizes. Fencing tokens close this
hole without requiring OS-level isolation.

**Mechanism.** `_system/agent-state/.fencing-counter` holds a single
monotonic integer. Each successful lease claim atomically increments and
reads the counter under an advisory file lock (`flock` with a bounded
wait), and the new value is stored on both the lease and every lock the
lease claims. Each write the agent performs is appended to `audit/` with
its `(scope, fencing_token)` pair.

**Invariant.** Validators MUST reject any write whose `fencing_token` is
strictly less than the current max recorded for its scope. A resumed-stale
agent — whose claim has since been re-issued under a higher counter value
— fails closed.

**Configuration.** `agent-instance-policy.json#/fencing`:

- `enabled` (default `true`) — turn off only on networked filesystems where
  POSIX advisory locks are unreliable; validators then emit a degraded-mode
  warning.
- `counter_path` — repo-relative path to the counter file.
- `monotonic` — invariant; MUST remain `true`.
- `stale_token_action` — `reject` (default) or `quarantine`.

**Operational note.** The counter file MUST NOT be deleted while any lease
is active. `reap-stale-leases.sh` (S3) checks counter consistency before
sweep; `check-agent-locks.sh` reports counter health.

## Validator entry points

- `bash bootstrap/check-agent-locks.sh <repo>` — per-scope lock invariants.
- `bash bootstrap/check-agent-instance-isolation.sh <repo>` (S3) — per-instance
  invariants (naming, caps, fencing monotonicity, lease/lock pairing).
- `bash bootstrap/check-agent-orchestration.sh <repo>` — fleet-level checks.
