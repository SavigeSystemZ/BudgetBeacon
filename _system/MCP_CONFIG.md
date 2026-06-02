# Model Context Protocol (MCP) Configuration

This document defines the standardized MCP posture used across AIAST app repos.
MCP servers provide optional tool access and repository context; they do not
override the repo-local instruction layer or project boundary rules.

## Isolation Contract

Every app gets its own MCP boundary:

- filesystem MCPs are scoped to the current app root only
- GitHub MCPs use repo-scoped credentials for the app's matching remote
- database/cache MCPs use app-specific development databases, schemas, or key prefixes
- browser automation MCPs use localhost app URLs and app-specific browser profiles
- memory/artifact MCPs use app-namespaced stores or `_system/context/`
- secrets live in user-local environment or secret storage, never tracked config

MCP roots help coordinate project context, but they are not a complete security
boundary. Treat every MCP server as trusted software with the access granted by
its command, environment, credentials, and working directory.

## Core MCP Set

| Server name | Purpose | Default scope | Config pattern |
| :--- | :--- | :--- | :--- |
| `project-filesystem` | Project file analysis and multi-file search. | Current app root only. | `{"args": ["-y", "@modelcontextprotocol/server-filesystem", "."]}` |
| `doc-lookup` | Official docs and current library references. | Read-only external lookup. | Provider-specific, token only if required. |
| `fetch` | Parse external web resources when references are needed. | Read-only external fetch. | `{"args": ["-y", "@modelcontextprotocol/server-fetch"]}` |
| `github-repo` | Issues, PRs, Actions, and branch coordination. | Matching app repo only. | Fine-grained repo token via environment. |

## Optional App-Scoped MCP Set

Add these only when the app needs them and they can be app-scoped:

| Server name | Use when | Required isolation |
| :--- | :--- | :--- |
| `browser-ui-smoke` | UI smoke tests or screenshots benefit from browser tools. | Localhost app URL and app-specific browser profile. |
| `sqlite-inspector` | The app uses repo-local SQLite. | Repo-local database path only. |
| `postgres-inspector` | The app uses PostgreSQL. | App-specific database and read-only credentials by default. |
| `redis-inspector` | The app uses Redis. | App-specific DB index or key prefix. |
| `observability-inspector` | The app has logs, traces, or dashboards to inspect. | App-local telemetry source. |
| `memory-artifact-store` | External memory is clearly needed. | App namespace; prefer `_system/context/` files first. |

## Tracked Config Rules

- Keep `.cursor/mcp.json` empty or placeholder-only unless the committed values
  are safe for every clone of the app.
- Use `_system/mcp/servers.cursor.example.json` and
  `_system/mcp/servers.codex.example.toml` as examples, not secret stores.
- Do not commit resolved home paths, sibling app paths, parent-template paths,
  root mounts, tokens, PATs, API keys, private keys, or real database URLs.
- If a host requires an absolute path, configure it in user-local IDE settings
  or an ignored local override.

## Agent-Specific Setup

### Cursor (MCP Settings)
1. Open Cursor Settings -> MCP.
2. Add only the servers the app needs.
3. Keep `project-filesystem` scoped to this workspace root.
4. Keep secrets in Cursor's local environment handling, not repo files.

### Windsurf (MCP Settings)
1. Open Windsurf Settings -> MCP.
2. Add only app-scoped servers using the same boundary rules.

### Antigravity CLI/Desktop
Antigravity currently reads MCP discovery through user-local Gemini/Antigravity config. Keep `~/.gemini/config/mcp_config.json` valid JSON even when no servers are configured:

```json
{
  "mcpServers": {}
}
```

Do not commit resolved Antigravity MCP paths, credentials, or host-global config into the repo. Keep project examples under `_system/mcp/` and use local overrides for host-specific values.

### Claude Desktop (config.json)
Use a user-local config with the resolved app path if the host requires one:

```json
{
  "mcpServers": {
    "project-filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "__AIAST_PROJECT_ROOT__"]
    }
  }
}
```

## Security & Drift Prevention

- **SSoT Rule:** Do not store API keys in this file. Use environment variables
  or local IDE secret storage.
- **Project Rule:** One app's MCP config must not mount, remember, authenticate,
  cache, or mutate another app's data.
- **Anti-Drift:** Any changes to reusable MCP requirements must be reflected in
  this file, `_system/mcp/MCP_PROJECT_ISOLATION_POLICY.md`, and the MCP catalog.
- **Validation:** Run `bash bootstrap/check-mcp-project-isolation.sh .` after
  changing MCP config, examples, catalog entries, or host adapter guidance.

## Capability Tiers & Instance Registry

Per-server-type isolation ceilings (T0–T3) live in
`_system/mcp/MCP_SERVER_CAPABILITY_TIER_MATRIX.md` (human form) and
`_system/mcp-server-capability-matrix.json` (machine form). Per-instance
enforcement uses `_system/mcp-instance-policy.json` and its schema.

Configured server instances are recorded under
`_system/mcp/instances/<mcp_instance_id>.json`; the lifecycle is defined
in `_system/mcp/MCP_INSTANCE_REGISTRY_PROTOCOL.md`. Host-absolute or
secret-bearing config goes under `_system/mcp/local-overrides/` (the
directory's `.gitignore` excludes everything except its README).
