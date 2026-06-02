# MCP Instance Registry Protocol

This document defines the **lifecycle of an MCP instance record** —
register, refresh, retire — and the registry surface that records it.
It is the MCP-side counterpart of `AGENT_INSTANCE_ISOLATION_POLICY.md`:
where that document governs *agent* identity and leases, this one
governs *MCP server instance* identity and registration. Together they
implement the V2 plan §9 boundary.

The protocol is **policy + state shape only**. The scripts that
exercise it (`register-mcp-instance.sh`, the extended
`check-mcp-project-isolation.sh`, `verify-mcp-provenance.sh`,
`check-mcp-bleed.sh`) land in S5. This document is a contract those
scripts MUST implement.

## What an "MCP instance" is

An MCP instance is one *configured* MCP server attached to a host
adapter inside a single AIAST app. Two apps configuring the same
underlying server binary are **two instances**, with different
`mcp_instance_id`s, different namespaces, and (where applicable)
different credentials. The matrix of which server *types* exist and
what tier they can reach is `MCP_SERVER_CAPABILITY_TIER_MATRIX.md`; this
document is about the *instances* of those types.

## State surfaces

```
_system/mcp/
  MCP_PROJECT_ISOLATION_POLICY.md
  MCP_INSTANCE_REGISTRY_PROTOCOL.md          ← this file
  MCP_SERVER_CAPABILITY_TIER_MATRIX.md
  MCP_SELECTION_POLICY.md
  MCP_FAILURE_FALLBACKS.md
  MCP_SERVER_CATALOG.md
  instances/                                  ← per-instance registry records (S5 populates)
    <mcp_instance_id>.json
  runtime/                                    ← non-tracked runtime state (host-fingerprint, provenance)
    host-fingerprint.json                     (generated, not tracked verbatim)
    mcp-server-provenance.jsonl               (append-only, retained per evidence policy)
  local-overrides/                            ← host-absolute config (gitignored except README)
    README.md
    .gitignore
```

`instances/` is tracked but seeded empty (`.gitkeep`) in the parent
template; downstream apps add records as they configure MCP servers.
`runtime/` and `local-overrides/` are gitignored except for the
explicit allowlist.

## Instance record shape

Every registry record under `_system/mcp/instances/<mcp_instance_id>.json`
MUST conform to the per-server-type entry in `mcp-instance-policy.json`
and carry the following base envelope:

```json
{
  "schema_version": "1.0.0",
  "mcp_instance_id": "<app_id>:mcp:<server_type>:<short_uuid>",
  "app_id": "<app_id from app-local-namespace.json>",
  "host_fingerprint_id": "fp_<sha256-12>",
  "server_type": "<one of mcp-server-capability-matrix.json types>",
  "server_package": {
    "id":      "<npm package id, container image, etc.>",
    "version": "<semver or container tag>",
    "integrity": "<sha256-... | container-digest | null>"
  },
  "tier_declared": "T0|T1|T2|T3",
  "tier_ceiling":  "T0|T1|T2|T3",
  "namespace_bindings": {
    "...":  "..."
  },
  "lifecycle": {
    "registered_at": "ISO-8601",
    "refreshed_at":  "ISO-8601",
    "retired_at":    null,
    "status":        "active|refreshing|retired|quarantined",
    "events": [
      { "ts": "ISO-8601", "kind": "registered", "by": "register-mcp-instance.sh" }
    ]
  }
}
```

Invariants enforced by `check-mcp-project-isolation.sh`:

1. `mcp_instance_id` MUST start with `<app_id>:mcp:` — matches the
   `namespaces.mcp` prefix defined in `app-local-namespace.json`.
2. `app_id` MUST match the surrounding `_system/app-local-namespace.json`.
3. `server_type` MUST appear in `mcp-server-capability-matrix.json`.
   `unknown` is refused in strict, warned in standard, allowed in
   lenient (mirrors the matrix's `unknown_handling`).
4. `tier_declared` MUST be `<=` `tier_ceiling` for this server type.
5. Every field listed in the matrix's `required_fields[]` for this
   server type MUST appear in `namespace_bindings` with a non-empty
   string value.
6. `lifecycle.status == "active"` ⇒ `retired_at` is `null`.
7. `lifecycle.status == "retired"` ⇒ `retired_at` is non-null and
   `events[]` ends with a `retired` event.

## Lifecycle

```
                ┌───────────────────────────┐
                │                           │
   register → active ──┬── refresh ─────────┘
                       │
                       ├── quarantine → quarantined ──┐
                       │                              │
                       ├── retire → retired ──────────┴── (forensic dir kept)
                       │
                       └── (provenance drift) → quarantined
```

### register

`register-mcp-instance.sh` (S5):

1. Reads `app-local-namespace.json`; refuses if missing or role is
   `parent-template`.
2. Reads `mcp-server-capability-matrix.json`; validates `--server-type`.
3. Reads `mcp-instance-policy.json`; loads the per-server-type policy
   entry.
4. Validates the supplied `--namespace-bindings` against the policy
   entry (every `required_fields[]` populated; allowed/denied roots
   honored).
5. Mints `mcp_instance_id` as `<app_id>:mcp:<server_type>:<short_uuid>`.
6. Captures provenance into `_system/mcp/runtime/mcp-server-provenance.jsonl`.
7. Writes the record atomically via `O_EXCL` to
   `_system/mcp/instances/<mcp_instance_id>.json`.
8. Emits a JSON envelope on stdout.

Refusal classes (machine-readable `error_code` values):

- `namespace_missing` — no `app-local-namespace.json`.
- `parent_template_refusal` — role sentinel says parent-template.
- `server_type_unknown` — strict profile, type not in matrix.
- `required_field_missing` — namespace-binding gap.
- `tier_above_ceiling` — `tier_declared > tier_ceiling`.
- `instance_id_in_use` — `O_EXCL` collision.
- `policy_violation` — denied-root, namespace-prefix mismatch, etc.

### refresh

A non-mutating revalidation. Re-runs every invariant against the
existing record; if the underlying `server_package.version` or
`integrity` has changed, an event of kind `provenance-drift` is
appended and (per F-17 expectation) severity-medium bleed event is
emitted. The record is **not** silently rewritten; the operator must
re-register or explicitly approve.

### quarantine

`quarantine-mcp-instance.sh` (S5) — operator primitive. Moves the
record to `_system/mcp/instances/quarantine/<mcp_instance_id>.json`,
appends a `quarantined` event with operator reason, and flips status.
The MCP server itself MUST NOT be reused by any agent while the record
is quarantined; agents discover this through the registry pass of
`check-mcp-project-isolation.sh`.

### retire

Clean shutdown of an instance the operator no longer needs. Flips
status to `retired`, sets `retired_at`, appends a `retired` event. The
record is **kept** (not deleted) so historical audit trails remain
joinable.

## Provenance

`_system/mcp/runtime/mcp-server-provenance.jsonl` is an append-only
log keyed by `mcp_instance_id`:

```jsonl
{"ts":"2026-05-12T15:00:00Z","mcp_instance_id":"...","kind":"register","package":{"id":"@modelcontextprotocol/server-filesystem","version":"0.6.2","integrity":"sha256-..."}}
{"ts":"2026-05-12T16:00:00Z","mcp_instance_id":"...","kind":"refresh","package":{"id":"@modelcontextprotocol/server-filesystem","version":"0.6.3","integrity":"sha256-..."}}
```

`verify-mcp-provenance.sh` (S5) reads this log and compares the current
on-disk package against the most recent `register`/`refresh` entry.
Mismatch ⇒ `provenance-drift` event (F-17).

## Validator entry points (S5 contract)

| Script | Mode | Refusals |
|---|---|---|
| `register-mcp-instance.sh`     | mutating | `error_code` from list above |
| `check-mcp-project-isolation.sh` | read-only | invariant violations 1–7; refusal under strict for unknown types |
| `verify-mcp-provenance.sh`     | read-only | drift events |
| `quarantine-mcp-instance.sh`   | mutating | operator-driven |
| `check-mcp-bleed.sh`           | read-only | cross-app references in registry, config, browser profiles |

## Cross-references

- `MCP_PROJECT_ISOLATION_POLICY.md` — boundary model.
- `MCP_SERVER_CAPABILITY_TIER_MATRIX.md` — server types + tier ceilings.
- `mcp-instance-policy.json` + schema — per-server-type policy.
- `mcp-server-capability-matrix.json` + schema — server-type catalog.
- `APP_LOCAL_NAMESPACE_CONTRACT.md` — source of `app_id` and namespace
  prefixes.
- `AGENT_INSTANCE_ISOLATION_POLICY.md` — sibling agent-instance contract.
- `_META_AGENT_SYSTEM/AIAST_MCP_AGENT_ISOLATION_FINALIZATION_PLAN_V2.md`
  §9, §11, §12 — design rationale + F-12/F-17 fault classes.
