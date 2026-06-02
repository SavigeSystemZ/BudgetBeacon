# Bleed-Event Protocol and Incident Response

When a validator detects that an isolation boundary has been crossed —
or could have been — it emits a structured **bleed event** to an
append-only JSONL log under
`_system/agent-state/audit/<YYYY-MM>.jsonl`. This document defines
that event shape, the severity-to-action matrix, and the operator
playbook that consumes the log.

This is the M3 / V2 §11+§12 deliverable: the layer that turns the
ad-hoc stderr error messages emitted by S5 validators into structured,
queryable telemetry. Validators continue to emit human-readable lines
to stderr; the bleed event is emitted *in addition*, never instead.

## Event shape

Schema: `_system/schemas/bleed-event.schema.json` (draft 2020-12,
`additionalProperties: false`).

```json
{
  "event_id":            "evt_<26-char ULID-ish>",
  "ts":                  "ISO-8601 UTC, second precision",
  "severity":            "critical | high | medium | low",
  "type":                "scope-escape | namespace-collision | lease-violation | host-clash | credential-leak | memory-authority-inversion | schema-violation | provenance-drift | template-app-confusion | unknown",
  "detected_by":         "<validator-script-name>",
  "agent_id":            "<id-or-null>",
  "app_id":              "<id-or-null>",
  "host_fingerprint_id": "<id-or-null>",
  "scope": {
    "path":      "<repo-relative or absolute>",
    "operation": "register | refresh | retire | quarantine | read | write | claim | release"
  },
  "intended_boundary": {
    "allowed_repo_root": "<realpath or null>"
  },
  "observed_target":     "<string-or-null>",
  "fencing_token":       0,
  "evidence_refs":       ["<file>#offset=<n>", "..."],
  "remediation": {
    "action": "quarantine | notify | allow | refused",
    "by":     "<script-or-operator>",
    "ts":     "ISO-8601"
  },
  "context": { "...free-form": "validator-specific details" }
}
```

All fields are required except `context`, which is an open free-form
object validators may populate with type-specific details (e.g.
`{"server_type": "browser", "expected_root": "/repo/.local/..."}`).

## Severity → action matrix

| Severity | Auto-quarantine | Block CI | Operator alert | Post-mortem required |
|----------|-----------------|----------|----------------|----------------------|
| critical | yes             | yes      | yes            | yes                  |
| high     | yes             | yes      | yes            | yes                  |
| medium   | no              | yes      | yes            | optional             |
| low      | no              | no       | log only       | no                   |

"Auto-quarantine" means the validator MAY invoke
`quarantine-agent.sh` / `quarantine-mcp-instance.sh` when it detects
the event. "Block CI" means the validator's exit code is non-zero so
CI fails. "Operator alert" means the event is surfaced via
`audit-bleed-events.sh` and (in M10) the `isolation-status.sh`
dashboard.

## Event type catalogue

| `type`                          | Canonical example | Detected by | Default severity |
|---------------------------------|-------------------|-------------|------------------|
| `scope-escape`                  | F-01, F-03, F-11, F-12 | `check-mcp-bleed.sh`, `check-mcp-project-isolation.sh` | critical/medium |
| `namespace-collision`           | F-02, F-10        | `check-app-local-namespace.sh`, `check-mcp-project-isolation.sh` | high/medium |
| `lease-violation`               | F-04, F-05, F-14  | `check-agent-instance-isolation.sh`, `init-agent-instance.sh` | high/critical |
| `host-clash`                    | F-06              | `check-agent-instance-isolation.sh` (M4+) | high |
| `credential-leak`               | F-08              | `check-mcp-project-isolation.sh`, `check-mcp-bleed.sh` | critical |
| `memory-authority-inversion`    | F-09              | `check-tool-memory-locality.sh` (M2+) | high |
| `schema-violation`              | F-13              | any JSON-schema gate | high |
| `provenance-drift`              | F-17              | `verify-mcp-provenance.sh` | medium |
| `template-app-confusion`        | F-07              | role-sentinel gates in every mutating script | critical |
| `unknown`                       | catch-all         | any validator         | medium |

## Lifecycle

```
   Detect ─► Emit event ─► (auto-quarantine if severity≥high)
                ↓
            audit/<YYYY-MM>.jsonl
                ↓
       audit-bleed-events.sh query
                ↓
   Operator reviews ─► remediate ─► append `remediation` event
                ↓
   Post-mortem to _META_AGENT_SYSTEM/INCIDENT_LOG.md (severity ≥ high)
```

Each remediation step is itself an event (`type = remediation`,
referenced via `evidence_refs[]` to the original event_id), so the log
captures both the bleed and the response chain.

## Append-only invariant

`audit/<YYYY-MM>.jsonl` is append-only. Validators MUST use the
`emit-bleed-event.sh` helper (or its Python equivalent) which:

- opens with `O_APPEND`,
- writes exactly one line terminated by `\n`,
- never rewrites or truncates existing content.

The file is also covered by
`_system/EVIDENCE_RETENTION_PROTECTED_ALLOWLIST.txt` so retention
sweeps cannot prune it.

## Query interface

`bootstrap/audit-bleed-events.sh`:

```
audit-bleed-events.sh <repo-root>
   [--since ISO]
   [--severity critical|high|medium|low|critical+|high+|medium+]
   [--type TYPE [...]]
   [--limit N]
   [--json]
```

`high+` means "high or critical"; `medium+` means medium/high/critical;
`critical+` is just critical. Without `--json` the script emits one
compact summary line per event; with `--json` it emits an array of
the matched events. Exit code is 0 if any events matched, 1 if none.

## Operator playbook

For severity ≥ high:

1. **Classify** — read the event's `type` and `severity`. If
   automated quarantine fired, the offending agent/MCP instance is
   already isolated.
2. **Quarantine if not already** — `quarantine-agent.sh` or
   `quarantine-mcp-instance.sh` with the event_id in the reason.
3. **Notify** — append a one-line summary to `WHERE_LEFT_OFF.md` and
   (severity ≥ high) to `_META_AGENT_SYSTEM/INCIDENT_LOG.md`.
4. **Snapshot** — capture the relevant audit slice + git status into
   the incident packet via the orphan-meta-snapshot tool
   (`snapshot-meta-to-orphan-branch.sh` covers the audit/ directory).
5. **Remediate** — release the quarantined record only after the
   root cause is closed; the release script appends a
   `remediation.action = released` event for traceability.
6. **Post-mortem** (severity ≥ high) — append to the incident log
   with class, root cause, control gap, and follow-up.

## Cross-references

- `_system/schemas/bleed-event.schema.json` — machine form.
- `bootstrap/emit-bleed-event.sh` — emitter helper used by validators.
- `bootstrap/audit-bleed-events.sh` — query.
- `_system/AGENT_INSTANCE_ISOLATION_POLICY.md` — agent-side bleed surfaces.
- `_system/mcp/MCP_INSTANCE_REGISTRY_PROTOCOL.md` — MCP-side bleed surfaces.
- `_system/EVIDENCE_RETENTION_PROTECTED_ALLOWLIST.txt` — covers
  `_system/agent-state/audit/*.jsonl`.
