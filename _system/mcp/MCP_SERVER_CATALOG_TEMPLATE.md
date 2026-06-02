# MCP Server Catalog Template

For each MCP server, record:

- name
- purpose
- command or URL
- environment schema, without secret values
- isolation boundary
- state/cache location
- baseline scopes
- elevation scopes
- risk rating
- audit requirements
- failure fallback

## Defaults

- no wildcard scopes
- baseline should be read-only or discovery-first
- elevation should be explicit, justified, and logged when the project requires auditability
- filesystem, database, browser, memory, cache, and GitHub scopes must be app-specific
- tracked config may use placeholders, but must not store resolved home paths or secrets
