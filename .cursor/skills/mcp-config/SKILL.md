---
name: mcp-config
description: Generate or review least-privilege MCP configs for this project.
---

# MCP Config

## Authority

1. `_system/MCP_CONFIG.md`
2. `_system/mcp/MCP_SELECTION_POLICY.md`
3. `_system/mcp/MCP_FAILURE_FALLBACKS.md`
4. `_system/mcp/MCP_SERVER_CATALOG.md`

## Rules

- Prefer read-only or discovery-first servers by default.
- Scope filesystem access to the project root — never grant home-directory or root access.
- Keep secrets outside repo files. Use environment variables or secret managers.
- Document what each server is for and why it is needed.
- Do not add a server unless it provides a concrete capability the project currently uses.
- If a server fails, the agent must be able to continue using fallback commands (see `MCP_FAILURE_FALLBACKS.md`).

## Config format examples

### Cursor (`.cursor/mcp.json`)

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-filesystem", "/path/to/project"],
      "env": {}
    }
  }
}
```

### Codex (`_system/mcp/servers.codex.example.toml`)

```toml
[servers.filesystem]
command = "npx"
args = ["-y", "@anthropic/mcp-filesystem", "/path/to/project"]
```

## Review checklist

1. Every server has a documented purpose.
2. Filesystem servers are scoped to project root, not broader.
3. No secrets or tokens appear in the config file.
4. Servers that require elevated access (write, database, deploy) are marked and justified.
5. Config parses without errors (`jq -e .` for JSON, `python3 -c "import tomllib; ..."` for TOML).
6. Failure fallback exists for each server (what command replaces it if MCP is unavailable).

## Deliverables

- updated MCP config or example with scoped access
- documented purpose for each server entry
- connectivity or syntax validation steps
- fallback commands for each server
