# MCP Project Isolation Policy

MCP servers are optional accelerators. They must never become a shared authority
that lets one app read, mutate, remember, or authenticate as another app.

## Boundary Model

Each installed app owns its own MCP boundary:

- repository root: the app directory that contains this AIAST install
- filesystem scope: the app repository root only
- memory scope: app-local continuity files or an app-namespaced external store
- database scope: the app's own development database or a read-only diagnostic user
- browser scope: the app's local dev URL and an app-specific browser profile
- GitHub scope: the app's matching repository only
- secrets scope: environment variables or local secret storage, never tracked files

The parent template repository has its own boundary and must not be mounted as an
MCP filesystem root for ordinary downstream app work.

## Roots Are Not Enough

MCP roots are useful for coordination and accident prevention, but they are not
a complete security boundary. Treat every MCP server as trusted software running
with the access granted by its command, environment, credentials, and working
directory. The client should expose only project-appropriate roots, and the
server configuration must still enforce least privilege.

## Tracked Config Rules

Tracked MCP config and examples may contain placeholders, not local absolute
paths:

- allowed placeholders: `.`, `__AIAST_PROJECT_ROOT__`, `${AIAST_PROJECT_ROOT}`,
  `${AIAST_PROJECT_ROOT:-.}`, `${workspaceFolder}`
- forbidden tracked roots: `/`, `~`, `$HOME`, `${HOME}`, `~/.MyAppZ`,
  `${HOME}/.MyAppZ`, `/home/.../.MyAppZ`, sibling app paths, and the parent
  template path
- forbidden tracked secrets: API keys, PATs, bearer tokens, private keys, and
  database URLs with real credentials

If a host requires an absolute filesystem path, put that resolved path in
user-local IDE settings or an ignored local override, not in the reusable repo
template.

## Baseline MCP Set

Use this baseline when the project benefits from MCP and the host supports it:

1. `project-filesystem`: scoped to the current app root only.
2. `doc-lookup`: read-only official documentation lookup.
3. `fetch`: read-only external resource parsing when web references are needed.
4. `github-repo`: repo-scoped issue, PR, and Actions inspection when the app has
   a GitHub remote and a fine-grained token.

## Optional App-Scoped Servers

Add these only when the app actually uses the capability:

- `browser-ui-smoke`: browser automation for local UI smoke checks; bind it to
  localhost app URLs and an app-specific browser profile.
- `sqlite-inspector`: repo-local SQLite files or generated development data.
- `postgres-inspector`: app-specific PostgreSQL database with read-only
  credentials by default.
- `redis-inspector`: app-specific Redis database or key prefix.
- `observability-inspector`: app-local logs, traces, or dashboards.
- `memory-artifact-store`: app-namespaced memory or artifacts. Prefer
  `_system/context/` files unless an external store is clearly needed.

## Bleed Prevention Checklist

Before adding or enabling an MCP server:

1. Identify the app root it is allowed to see.
2. Identify the credentials it receives and prove they are repo-scoped or
   app-scoped.
3. Identify where it stores state, cache, memory, browser profiles, and logs.
4. Confirm that no sibling app directory, parent template directory, home
   directory, or global mutable store is mounted by default.
5. Add or update the entry in `_system/mcp/MCP_SERVER_CATALOG.md`.
6. Run `bash bootstrap/check-mcp-project-isolation.sh .`.

## Failure Rule

If an MCP server cannot be made app-scoped, do not enable it. Use native shell,
host tooling, or a narrower server instead.

## Capability Tiers

Not every MCP server type can reach the same isolation tier at runtime.
The authoritative catalog is `MCP_SERVER_CAPABILITY_TIER_MATRIX.md`
(human form) and `_system/mcp-server-capability-matrix.json` (machine
form). Tier semantics:

- **T0** — documentation + naming only.
- **T1** — static configuration boundary (`allowed_repos[]`,
  `allowed_paths_regex`, etc.).
- **T2** — process / scaffold contract (working directory, scaffold gate).
- **T3** — runtime per-instance separation (per-instance credentials,
  namespaced cache, per-instance profile directory, realpath-checked
  roots).

Per-instance enforcement uses `_system/mcp-instance-policy.json` and its
schema. The validator `bootstrap/check-mcp-project-isolation.sh` refuses
any instance whose declared type is `unknown` under the `strict`
profile (closes fault F-12 in the V2 isolation plan); under `standard`
it is allowed with a warning, under `lenient` it is allowed silently.

## Instance Registry

Each configured MCP server attached to this app is recorded as a JSON
record under `_system/mcp/instances/<mcp_instance_id>.json`. Lifecycle
(register / refresh / retire / quarantine) and required record fields
are defined in `MCP_INSTANCE_REGISTRY_PROTOCOL.md`. The
`mcp_instance_id` always starts with `<app_id>:mcp:`, matching the
`namespaces.mcp` prefix from `_system/app-local-namespace.json`.

## Cross-references

- `MCP_SERVER_CAPABILITY_TIER_MATRIX.md` — server-type × tier catalog (T0–T3).
- `MCP_INSTANCE_REGISTRY_PROTOCOL.md` — instance record lifecycle.
- `../mcp-server-capability-matrix.json` + schema — machine form of the matrix.
- `../mcp-instance-policy.json` + schema — per-server-type policy.
- `../APP_LOCAL_NAMESPACE_CONTRACT.md` — source of `app_id` and namespace prefixes.
- `../AGENT_INSTANCE_ISOLATION_POLICY.md` — sibling agent-instance isolation contract.
