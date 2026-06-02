# MCP Server Capability Tier Matrix

This document is the authoritative human-form companion to
`_system/mcp-server-capability-matrix.json`. It enumerates the MCP server
types AIAST recognises, the isolation primitives each one supports, the
maximum isolation tier (T0..T3) achievable for that server type, and the
namespace fields an instance of that type MUST carry. Validators consult
the machine form; this document explains the intent.

The matrix is the antidote to one concrete failure class:

> **F-12 — Unknown MCP server type in strict mode.**
> A server whose `type` does not appear in the matrix MUST be refused by
> `bootstrap/check-mcp-project-isolation.sh` when the validation profile
> is `strict`. Under `standard` it is allowed with a warning; under
> `lenient` it is allowed silently. There is no implicit "anything
> goes" tier.

Isolation tiers are layered (see `AGENT_INSTANCE_ISOLATION_POLICY.md` and
the V2 plan `_META_AGENT_SYSTEM/AIAST_MCP_AGENT_ISOLATION_FINALIZATION_PLAN_V2.md`):

| Tier | Mechanism | Example primitives |
|------|-----------|--------------------|
| T0   | Documentation + naming convention | catalog entry, capability declaration |
| T1   | Static configuration boundary | `allowed_repos[]`, `base_url`, `allowed_paths_regex` |
| T2   | Process / scaffold contract | working directory, scaffold gate |
| T3   | Runtime per-instance separation | per-instance creds, namespaced cache, per-instance profile dir, realpath-checked roots |

A server's **tier ceiling** is the *highest* tier its runtime can reach
when configured correctly. A server may always be operated *below* its
ceiling, never above it.

## The matrix

| Server type | Allowed-roots? | Per-instance creds? | Namespaceable cache? | Tier ceiling | Required namespace fields |
|---|---|---|---|---|---|
| `filesystem`             | yes | n/a | n/a                          | T3 | `allowed_roots[]`, `denied_roots[]` |
| `github`                 | n/a | yes (per-PAT scope) | n/a              | T3 | `credentials_scope`, `allowed_repos[]` |
| `postgres`               | n/a | yes | yes (schema prefix)          | T3 | `db_schema_or_prefix` |
| `redis`                  | n/a | yes | yes (db index + key prefix)  | T3 | `db_index`, `cache_namespace` |
| `browser`                | yes (profile dir) | n/a | yes (profile)      | T3 | `browser_profile_path` |
| `memory_artifact`        | n/a | n/a | yes (namespace)              | T3 | `memory_namespace` |
| `http_remote`            | n/a | yes | n/a                          | T1 | `base_url`, `allowed_paths_regex` |
| `unknown`                | n/a | n/a | n/a                          | T0 | (none — refused in strict) |

Eight rows. The eighth row (`unknown`) is a sentinel: it exists so the
validator has something concrete to point at when refusing a server type
the catalog does not recognise. Operators who genuinely need a new
server type extend the matrix (and its schema) rather than relying on
`unknown`.

## Per-row notes

### `filesystem`
The stdio filesystem MCP. Tier ceiling is reached only when every entry
of `allowed_roots[]` is `realpath`-canonicalised at scaffold time and
verified to live *inside* `repo_root_realpath` (and *outside* the parent
template path in downstream mode). `denied_roots[]` is an additive
belt-and-braces list for paths the operator wants explicitly refused
even if they would otherwise pass — e.g. `.git/objects` for read-only
agents.

### `github`
PAT or fine-grained-token scoped to a specific repository. The
`credentials_scope` field is the **declaration** of what the operator
intended ("repo:owner/name read"); `allowed_repos[]` is the
**enforcement** list the runtime hands to the server. Both MUST be
present so a drifted token (broader than declared) can be detected by
comparing observed token scope against `credentials_scope`.

### `postgres`
Per-app database OR per-app schema prefix on a shared database. The
field `db_schema_or_prefix` is mandatory regardless of which strategy is
used — when it is a database name, validators check the connection
string matches; when it is a schema prefix, validators ensure every
generated DDL respects the prefix. F-10 (missing `db_schema_or_prefix`)
is detected here.

### `redis`
`db_index` selects a numeric Redis DB; `cache_namespace` is the key
prefix every write MUST carry. Both are required because either alone is
insufficient: shared `db_index` with prefix is acceptable, separate
`db_index` without prefix is acceptable, neither is not.

### `browser`
Playwright / Puppeteer / similar. `browser_profile_path` MUST resolve
inside `<repo_root>/.local/browser-profiles/<app_id>/<mcp_instance_id>/`.
F-11 (browser profile outside expected tree) is detected by realpath
comparison.

### `memory_artifact`
A memory or artifact store keyed by a namespace string. The
`memory_namespace` MUST start with `<app_id>:` so that cross-app reads
cannot resolve to another app's records even when the underlying store
is shared. Combined with `PROJECT_LOCAL_TOOL_MEMORY_STANDARD.md`'s
write-direction rules this prevents F-09 (memory authority inversion).

### `http_remote`
Tier ceiling is T1: there is no runtime mechanism inside AIAST that can
sandbox a remote HTTP endpoint, so the only enforceable boundary is
configuration-level. `allowed_paths_regex` is matched against every
outbound path. The fact that this server type *cannot* reach T3 is the
reason it has its own row — operators who want T3 must pick a different
server type or wrap the remote endpoint behind a local proxy that does
reach T3.

### `unknown`
The sentinel. Never used by a real instance; emitted by the validator
when a registry record declares a `type` not in this matrix. Tier
ceiling T0 means "documentation only — no runtime guarantees". The
validator behaviour by profile is:

| Profile | `type: unknown` outcome |
|---------|--------------------------|
| `strict`   | **refused** (exit non-zero) |
| `standard` | warning + counted in audit |
| `lenient`  | silent (still counted) |

## Adding a new server type

1. Append a row to the table above with realistic mechanism columns.
2. Add a matching entry to `_system/mcp-server-capability-matrix.json`
   that mirrors the row exactly.
3. Update `_system/schemas/mcp-server-capability-matrix.schema.json` if
   the new row requires a new `required_fields` value not already in the
   schema's `mcp_field_name` enum.
4. Update `_system/mcp-instance-policy.json` if the new server type
   needs per-server policy.
5. Update `_system/mcp/MCP_PROJECT_ISOLATION_POLICY.md`'s cross-link
   section.
6. Regenerate `SYSTEM_REGISTRY.json`, `KEY.md`,
   `SUPER_TEMPLATE_MASTER_MAP.md`, `INTEGRITY_MANIFEST.sha256`.
7. Run `validate-system.sh TEMPLATE --strict` and
   `system-doctor.sh TEMPLATE`.

## Cross-references

- `MCP_PROJECT_ISOLATION_POLICY.md` — boundary model + tier semantics.
- `MCP_INSTANCE_REGISTRY_PROTOCOL.md` — instance record lifecycle.
- `mcp-server-capability-matrix.json` + schema — machine form.
- `mcp-instance-policy.json` + schema — per-server-type allowed/denied
  roots, required namespace fields, capability tier binding.
- `APP_LOCAL_NAMESPACE_CONTRACT.md` — where `app_id` and namespace
  prefixes come from.
- `AGENT_INSTANCE_ISOLATION_POLICY.md` — sibling instance contract for
  agents.
