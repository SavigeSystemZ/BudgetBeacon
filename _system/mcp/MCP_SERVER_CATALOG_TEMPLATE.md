# MCP Server Catalog Template

For each MCP server, record:

- name
- purpose
- command or URL
- environment schema, without secret values
- baseline scopes
- elevation scopes
- risk rating
- audit requirements
- failure fallback

## Defaults

- no wildcard scopes
- baseline should be read-only or discovery-first
- elevation should be explicit, justified, and logged when the project requires auditability
