# Agent Instance Isolation Policy

This policy specifies how individual agent **instances** are named, claimed,
heartbeat'd, fenced, retired, and capped per repo. It complements:

- `AGENT_LOCKING_AND_LEASES.md` — per-scope lock lifecycle.
- `CONCURRENT_AGENT_FLEET_PROTOCOL.md` — fleet-level coordination.
- `MULTI_AGENT_COORDINATION.md` — role/lane orchestration.
- `APP_LOCAL_NAMESPACE_CONTRACT.md` — the `app_id` every lease is scoped to.

Machine-form: `_system/agent-instance-policy.json` (validated against
`_system/schemas/agent-instance-policy.schema.json` in `--strict`).

Design rationale: `_META_AGENT_SYSTEM/AIAST_MCP_AGENT_ISOLATION_FINALIZATION_PLAN_V2.md` §8.

## Why "instance" and not just "agent"

A single agent **type** (e.g. `cursor`) may run many concurrent **instances**
(`cursor-01`, `cursor-02`, ...) inside one repo *or* across repos. The
instance identity is what locks, heartbeats, fencing tokens, and audit events
are keyed on. AIAST previously talked about `agent_id` generically; this
policy makes "instance" a first-class concept.

## Agent ID grammar

```
agent_id ::= <agent_type>-<NN>
agent_type ∈ { cursor, codex, claude, gemini, copilot, windsurf, aider,
               agentzero, local-model }
NN ::= [0-9]{2,3}
```

The canonical anchored regex lives in `agent-instance-policy.json#/naming/regex`.
A new agent type is added by:

1. extending `naming.allowed_agent_types` and `naming.regex`,
2. adding the type to `concurrency_caps`,
3. adding a matching tool-memory stub under `_system/tool-memory/`.

`agent_id` is **unique-per-repo**. Two instances with the same `agent_id`
on the same repo MUST never hold an active lease at the same time. Across
repos, `agent_id` reuse is permitted; multi-host clash detection (§7) is
the relevant control there.

## State layout reconciliation: `locks/` vs `leases/`

AIAST ships two adjacent state directories that previously had overlapping
semantics. This policy fixes them:

| Directory | Purpose | File granularity | Keyed on |
|---|---|---|---|
| `locks/` | **Per-scope mutex.** Records who currently owns write access to a glob/path scope. Existing convention. | one per active scope | `<scope_hash>.lock.json` |
| `leases/` | **Per-instance identity record.** Records the agent's identity, role, lane, branch, the set of scopes it currently holds, and its fencing token. | one per active instance | `<agent_id>.lease.json` |

Both are present concurrently when an instance is active. The lease is the
identity-of-record; the locks are the scope grants the lease holds. A
release path removes a lock; a quarantine path moves both lock and lease
into `quarantine/` for forensic inspection.

`heartbeats/<agent_id>.json` — touch-file used for liveness. Independent of
the lease so that crash detection is read-cheap.

`conflicts/<ts>-conflict.md` — operator-facing record. Created by the reaper
when a stale lease is auto-quarantined, or by a tool when a same-ID claim
race is detected.

`audit/<YYYY-MM>.jsonl` — append-only structured event log; bleed events
land here (added in S11).

`quarantine/<agent_id>/` — atomic snapshot of `lease + locks + last
heartbeat` for any instance frozen pending operator review.

`active-agents.json` — derived index, regenerable from the directories
above. Convenience for fast listing; not authoritative.

## Lease record shape

```json
{
  "schema_version": "1.0.0",
  "agent_id": "cursor-02",
  "agent_type": "cursor",
  "app_id": "budgetbeacon-019e19e4",
  "host_fingerprint_id": "fp_000000000000",
  "process_id": 12345,
  "process_start_epoch": 1715472000,
  "role": "implementation-worker",
  "lane": "frontend-ui",
  "branch": "ai/cursor-02/frontend-ui",
  "scopes": [
    {
      "scope": "src/features/budget/**",
      "lock_path": "_system/agent-state/locks/<scope_hash>.lock.json",
      "claimed_at": "2026-05-11T12:00:00Z"
    }
  ],
  "forbidden_roots": [
    "/abs/path/to/parent_template",
    "/abs/path/to/sibling/app"
  ],
  "fencing_token": 1715472017000003,
  "lease_started_at": "2026-05-11T12:00:00Z",
  "lease_expires_at": "2026-05-11T12:05:00Z",
  "heartbeat_at": "2026-05-11T12:04:30Z",
  "heartbeat_interval_seconds": 30,
  "ttl_seconds": 300,
  "status": "active"
}
```

Status values: `active | expiring | expired | quarantined | released`.

## Fencing tokens (closes the race-condition hole)

Time-based lease expiry is not sufficient. A paused process can resume past
its TTL and emit writes that are no longer authorized. Fencing tokens
defend against this without OS-level isolation.

**Counter:** `_system/agent-state/.fencing-counter` is a monotonic counter
file. Each successful lease claim atomically increments and reads the
counter under an advisory file lock (`flock`), and the new value is stored
on the lease as `fencing_token`.

**Invariant:** every write the agent performs is logged with its
`(scope, fencing_token)` in `audit/`. Validators reject writes from a
`fencing_token` strictly less than the current max recorded for that scope.
A resumed-stale agent — whose lease has been re-issued to someone else
under a higher counter value — is fail-closed at audit time.

**Counter file format:** a single decimal integer on the first line. The
counter is read-modify-written under `flock` with a 5-second wait timeout
and bumped atomically via temp-and-rename.

**NFS/network-filesystem caveat:** advisory locks on networked filesystems
are unreliable. `agent-instance-policy.json` may set
`fencing.enabled: false` for repos on such filesystems; validators emit a
degraded-mode warning. T6 OS-isolation recipes (see
`MULTI_REPO_CONCURRENCY_BOUNDARY.md`, added in S7) describe alternatives.

**Stale-token action:** controlled by
`agent-instance-policy.json#/fencing/stale_token_action` —
`reject` (default) fails the write; `quarantine` additionally moves the
agent into `quarantine/`.

## Lease lifecycle

```
   ┌─────────┐  claim    ┌────────┐  heartbeat        ┌─────────┐
   │  null   │──────────▶│ active │ ◀─── periodic ───▶│ active  │
   └─────────┘           └───┬────┘                   └────┬────┘
                             │ release                     │ no hb > ttl
                             ▼                             ▼
                        ┌──────────┐                  ┌──────────┐
                        │ released │                  │ expiring │
                        └──────────┘                  └────┬─────┘
                                                           │ no hb in grace
                                                           ▼
                                                     ┌──────────┐
                                                     │ expired  │
                                                     └────┬─────┘
                                                          │ reaper sweep
                                                          ▼
                                                     ┌─────────────┐
                                                     │ quarantined │
                                                     └─────────────┘
```

- **claim** — atomic O_EXCL create of the lock file and the lease file; bump
  the fencing counter; write the heartbeat. If any step fails, all prior
  steps are rolled back. The whole sequence is wrapped in `flock` on the
  counter file so two simultaneous claims serialize.
- **heartbeat** — touch `heartbeats/<agent_id>.json`; recompute
  `lease_expires_at = now + ttl`.
- **expiring** — `now >= lease_expires_at` and the reaper hasn't run yet;
  one heartbeat-interval grace cycle is given.
- **expired** — grace exhausted. Eligible for the reaper. Writes from this
  agent are refused (fencing) and any new claim with the same `agent_id`
  is permitted.
- **quarantined** — the reaper has moved `lease + locks + last heartbeat`
  to `quarantine/<agent_id>/`. The slot is freed; an operator decides
  whether to investigate, then runs `release-agent.sh` to clear, or
  escalates. Quarantined state is the source of forensic evidence.

Default policy: `expired_action: "quarantine"`. Setting `delete` permanently
drops the record (not recommended). Setting `release` puts the lease back
into the pool without forensic snapshot.

## Concurrency caps

`agent-instance-policy.json#/concurrency_caps` maps `agent_type → max
instances per repo`. Defaults reflect typical machine constraints:

| Type | Default cap |
|---|---|
| cursor | 5 |
| codex | 3 |
| claude | 3 |
| gemini | 3 |
| copilot | 2 |
| windsurf | 2 |
| aider | 2 |
| agentzero | 2 |
| local-model | 2 |

`init-agent-instance.sh` (S3) refuses to claim when adding this instance
would exceed the cap. The cap is per-repo; cross-repo concurrency is
unlimited and controlled by `MULTI_REPO_CONCURRENCY_BOUNDARY.md` (S7).

## Multi-host

V1 of this policy treats `host_fingerprint_id` as optional. S7 promotes it
to required for repos that opt in via
`agent-instance-policy.json#/multi_host/require_host_fingerprint`.
`on_host_clash` chooses `warn` (default) vs `refuse` when two heartbeats
arrive with the same `agent_id` from different fingerprints.

## Forbidden roots

Every lease records the resolved set of `forbidden_roots` it inherited from
`app-local-namespace.json#/forbidden_roots` at claim time. Validators
cross-check write paths against this list; writes targeting a forbidden
root are refused and audited as `scope-escape` events.

## Validation invariants

Enforced by `check-agent-instance-isolation.sh` (S3):

- Every active `leases/<id>.lease.json` has a matching `heartbeats/<id>.json`.
- Every active lease's `agent_id` matches the naming regex.
- For each `agent_type`, count of `active` leases ≤ `concurrency_caps[type]`.
- No two active leases share the same `agent_id`.
- Every lease's `app_id` equals `app-local-namespace.json#/app_id`.
- For each lock in `locks/`, exactly one lease claims it via `scopes[]`.
- `fencing_token` values are monotonically non-decreasing in claim order
  recorded under `audit/`.
- No active lease has `fencing_token` strictly less than the current
  counter value for any scope it claims.

## Cross-references

- `AGENT_LOCKING_AND_LEASES.md` — lock lifecycle + reclaim policy, now with
  the fencing-token addendum.
- `APP_LOCAL_NAMESPACE_CONTRACT.md` — provides `app_id` and `forbidden_roots`.
- `CONCURRENT_AGENT_FLEET_PROTOCOL.md` — fleet-level rules.
- `AGENT_AND_MCP_BLEED_PREVENTION_MATRIX.md` (S7) — maps lease violations to
  bleed event severity.
- `BLEED_EVENT_AND_INCIDENT_RESPONSE.md` (S11) — what happens after a
  quarantine.

## Acceptance (S2 milestone gate)

This slice is complete when:

1. `agent-instance-policy.json` validates against its schema.
2. `AGENT_LOCKING_AND_LEASES.md` contains an explicit fencing-token section
   referencing this policy.
3. Naming regex matches all 9 default `agent_type` values + `-01` through
   `-99`/`-100..-999`.
4. State-layout fields in the manifest match real directories in
   `_system/agent-state/`.
5. `validate-system.sh TEMPLATE --strict` continues to report `system_ok`.
6. Scripts that will consume the manifest (S3) have a stable contract to
   target.
