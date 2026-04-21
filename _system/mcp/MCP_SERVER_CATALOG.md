# MCP Server Catalog

Use this file to record actual servers approved for the project.

## Entry template

- Name:
- Purpose:
- Command or URL:
- Environment schema:
- Baseline scopes:
- Elevated scopes:
- Risk rating:
- Audit expectations:
- Failure fallback:

## Starter baseline

### project-filesystem

- Name: project-filesystem
- Purpose: scoped project file access
- Command or URL: local filesystem server
- Environment schema: none
- Diagnostic: `ls TEMPLATE/_system/`
- Baseline scopes: project root read or read/write as project policy allows
- Elevated scopes: none beyond repo scope
- Risk rating: medium
- Audit expectations: note if write access is enabled
- Failure fallback: shell or native file tooling inside the repo

### doc-lookup

- Name: doc-lookup
- Purpose: fetch official documentation or library references
- Command or URL: user-level or hosted MCP
- Environment schema: token if required, not stored here
- Diagnostic: `mcp:brave-search:search "AIAST documentation"`
- Baseline scopes: read-only
- Elevated scopes: none
- Risk rating: low
- Audit expectations: none beyond usage note
- Failure fallback: repo docs and primary-source web browsing when allowed

### postgres-inspector

- Name: postgres-inspector
- Purpose: query running PostgreSQL database for schema and data verification
- Command or URL: local or containerized MCP
- Environment schema: `PG_URL` (read-only credentials required)
- Diagnostic: `mcp:postgres:query "SELECT 1"`
- Baseline scopes: read-only (SELECT, EXPLAIN)
- Elevated scopes: schema mutation (not recommended)
- Risk rating: high
- Audit expectations: requires strict read-only user enforcement
- Failure fallback: manual psql queries or admin console

### redis-inspector

- Name: redis-inspector
- Purpose: query running Redis instance for keys and latency checks
- Command or URL: local or containerized MCP
- Environment schema: `REDIS_URL`
- Diagnostic: `mcp:redis:info`
- Baseline scopes: read-only (GET, INFO, KEYS)
- Elevated scopes: write access (FLUSHDB)
- Risk rating: medium
- Audit expectations: ensure no sensitive keys are leaked
- Failure fallback: redis-cli

### github-actions-monitor

- Name: github-actions-monitor
- Purpose: inspect CI/CD build status and fetch logs
- Command or URL: user-level or hosted MCP
- Environment schema: `GITHUB_TOKEN` (fine-grained, read-only)
- Diagnostic: `mcp:github:whoami`
- Baseline scopes: read actions, read logs
- Elevated scopes: trigger workflow
- Risk rating: medium
- Audit expectations: ensure token is strictly scoped to the repository
- Failure fallback: web browser
