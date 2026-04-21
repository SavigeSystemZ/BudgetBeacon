# Model Context Protocol (MCP) Configuration

This document defines the standardized set of MCP servers used across the AIAST Swarm Fleet to provide agents with consistent tool access and repository context.

## Core MCP Fleet

| Server Name | Purpose | Suggested Config (JSON) |
| :--- | :--- | :--- |
| **@modelcontextprotocol/server-filesystem** | Repository-wide file analysis and multi-file search. | `{"args": ["-y", "@modelcontextprotocol/server-filesystem", "./"]}` |
| **@modelcontextprotocol/server-brave-search** | Real-time research, documentation lookup, and troubleshooting. | `{"args": ["-y", "@modelcontextprotocol/server-brave-search"], "env": {"BRAVE_API_KEY": "..."}}` |
| **@modelcontextprotocol/server-github** | Issue management, PR review, and branch coordination. | `{"args": ["-y", "@modelcontextprotocol/server-github"], "env": {"GITHUB_PERSONAL_ACCESS_TOKEN": "..."}}` |
| **@modelcontextprotocol/server-fetch** | Parsing external web resources and documentation. | `{"args": ["-y", "@modelcontextprotocol/server-fetch"]}` |

## Agent-Specific Setup

### Cursor (MCP Settings)
1. Open Cursor Settings -> MCP.
2. Add a new server for each item in the fleet above using the provided `npx` command line.
3. Ensure the `filesystem` server is restricted to the current project root.

### Windsurf (MCP Settings)
1. Open Windsurf Settings -> MCP.
2. Add servers using the same `npx` arguments as Cursor.

### Claude Desktop (config.json)
Merge the following into your `claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/absolute/path/to/project"]
    }
  }
}
```

## Security & Drift Prevention
- **SSoT Rule:** Do not store API keys in this file. Use environment variables or local IDE secret storage.
- **Anti-Drift:** Any changes to the fleet requirements must be proposed via a `fleet_architect` plan and reflected in this file before being applied to IDE configurations.
