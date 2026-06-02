# Scaffold Isolation Completion Gate

A **scaffold isolation completion gate** is the single source of truth
for "this downstream app is correctly isolated." It runs a canonical
sequence of validators and reports pass/fail plus the bleed-event
delta each step emitted. Operators run it on demand; `init-project.sh`
runs it automatically at the end of a downstream scaffold (in
best-effort mode); CI can run it with `--strict` to gate merges.

The machine form of the gate list lives in
`_system/scaffold-isolation-gates.json` (draft 2020-12 schema at
`_system/schemas/scaffold-isolation-gates.schema.json`). The runner
is `bootstrap/check-scaffold-isolation-gate.sh`.

## Why this exists

Every previous slice landed a validator. Each is correct in
isolation, but operators (and CI) need to ask one question — *"is
this downstream app safely isolated?"* — and get one answer. Running
five scripts and synthesising their outputs by hand is error-prone
and silently drifts.

The gate also makes the bleed-event telemetry from S6 useful: each
step's *delta* against the audit log shows operators which gate
caused which events.

## Default gate sequence

Order matters. Earlier gates establish preconditions later gates
depend on (e.g. a missing app-local namespace makes the registry
pass meaningless). The runner executes them in order; under
`--strict` it stops at the first non-zero exit so the resulting
envelope identifies the root cause.

| # | Gate id | Validator | Required outcome | Severity if failed |
|---|---------|-----------|-------------------|--------------------|
| 1 | `app-local-namespace`           | `bootstrap/check-app-local-namespace.sh`           | exit 0 | high |
| 2 | `agent-instance-isolation`      | `bootstrap/check-agent-instance-isolation.sh`      | exit 0 | high |
| 3 | `mcp-project-isolation-strict`  | `bootstrap/check-mcp-project-isolation.sh --profile strict --emit-bleed-events` | exit 0 | high |
| 4 | `mcp-bleed`                     | `bootstrap/check-mcp-bleed.sh --emit-bleed-events` | exit 0 | high |
| 5 | `mcp-provenance-strict`         | `bootstrap/verify-mcp-provenance.sh --strict --emit-bleed-events` | exit 0 | medium |

Gates 3–5 use `--emit-bleed-events` so the audit log captures
structured records of any failures (per
`_system/BLEED_EVENT_AND_INCIDENT_RESPONSE.md`).

## Runner modes

| Mode | Behaviour |
|------|-----------|
| `--strict` (CI default) | First non-zero exit aborts; returns rc=1; later gates skipped |
| `--best-effort` (init-project default) | Every gate runs; rc=0 even on failures; per-step status surfaced |
| `--report-only` | Same as best-effort, but never appends bleed events even if validators support it |
| `--skip GATE_ID` (repeatable) | Named gate skipped (reason recorded) |

## Envelope

```json
{
  "ok": true,
  "script": "check-scaffold-isolation-gate.sh",
  "ts": "2026-05-12T15:30:00Z",
  "mode": "best-effort",
  "target": "/abs/repo",
  "role": "downstream-app",
  "app_id": "...",
  "gates": [
    {
      "id": "app-local-namespace",
      "command": "bootstrap/check-app-local-namespace.sh",
      "ok": true,
      "rc": 0,
      "duration_seconds": 0.12,
      "bleed_events_emitted": 0,
      "stderr_tail": ""
    }
    // ... one entry per gate
  ],
  "summary": {
    "total":    5,
    "ok":       5,
    "failed":   0,
    "skipped":  0,
    "bleed_events_total": 0,
    "first_failure": null
  }
}
```

`first_failure` (when set) names the first failing gate id so an
ops dashboard can highlight the root cause without parsing every
step.

## Integration

- `bootstrap/init-project.sh` runs the gate in `--best-effort` mode
  at the very end of a downstream scaffold and prints a one-line
  summary. Failures are reported but do not block initialisation;
  operators run the gate again with `--strict` once they've
  addressed any issues.
- CI workflows targeting downstream apps SHOULD run the gate with
  `--strict` and fail the build on rc != 0.
- The orphan meta snapshot tool covers `_system/agent-state/audit/`
  by default, so any bleed events emitted by the gate are captured
  in the cloud backup automatically.

## Anti-policy

- The gate MUST NOT mutate state. It is read-only with the single
  exception of appending to `_system/agent-state/audit/<YYYY-MM>.jsonl`
  via the opt-in `--emit-bleed-events` forwarding.
- The gate MUST NOT run inside the AIAST parent template. It is a
  downstream-only contract; the role-sentinel gate inside each
  underlying validator enforces this.
- Adding a new gate requires updating both
  `scaffold-isolation-gates.json` AND this document. The runner
  refuses to execute a gate not listed in the manifest.

## Cross-references

- `bootstrap/check-scaffold-isolation-gate.sh` — runner.
- `scaffold-isolation-gates.json` + schema — machine form.
- `_system/BLEED_EVENT_AND_INCIDENT_RESPONSE.md` — event log this
  gate populates via downstream `--emit-bleed-events`.
- `_system/AGENT_INSTANCE_ISOLATION_POLICY.md` — gate 2's contract.
- `_system/APP_LOCAL_NAMESPACE_CONTRACT.md` — gate 1's contract.
- `_system/mcp/MCP_INSTANCE_REGISTRY_PROTOCOL.md` — gate 3's contract.
- `_system/ORPHAN_META_SNAPSHOT_POLICY.md` — covers the audit dir.
