# MCP Templates

These files are example configurations and should be adapted per client.

## Included

- `servers.cursor.example.json`
- `servers.codex.example.toml`
- `MCP_PROJECT_ISOLATION_POLICY.md`

## Rules

- Keep secrets out of repo files.
- Prefer read-only or discovery-first servers.
- Scope filesystem access to the project root only.
- Add higher-privilege tools only when needed.
- Keep memory, browser profiles, databases, caches, and GitHub tokens app-scoped.
- Run `bash bootstrap/check-mcp-project-isolation.sh .` after MCP changes.
