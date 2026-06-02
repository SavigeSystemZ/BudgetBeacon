# MCP Server Catalog

Use this file to record actual servers approved for the project.

## Entry template

- Name:
- Purpose:
- Command or URL:
- Environment schema:
- Isolation boundary:
- State/cache location:
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
- Isolation boundary: current app repository root only
- State/cache location: none
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
- Isolation boundary: read-only external documentation lookup
- State/cache location: provider-local cache only; no project memory
- Diagnostic: `mcp:brave-search:search "AIAST documentation"`
- Baseline scopes: read-only
- Elevated scopes: none
- Risk rating: low
- Audit expectations: none beyond usage note
- Failure fallback: repo docs and primary-source web browsing when allowed

### fetch

- Name: fetch
- Purpose: parse external web resources when the task depends on a referenced page
- Command or URL: local or hosted fetch MCP
- Environment schema: none by default
- Isolation boundary: read-only external URLs selected for the active task
- State/cache location: none or provider-local cache
- Diagnostic: fetch a known public documentation page
- Baseline scopes: read-only
- Elevated scopes: none
- Risk rating: low
- Audit expectations: cite or record externally sourced facts where appropriate
- Failure fallback: browser or allowed web lookup

### github-repo

- Name: github-repo
- Purpose: inspect the matching GitHub mirror repo and Actions for this app
- Command or URL: user-level or hosted GitHub MCP
- Environment schema: `GITHUB_TOKEN` or `GITHUB_PERSONAL_ACCESS_TOKEN` with fine-grained repo scope
- Isolation boundary: matching GitHub repository for this app only; default
  model is a private full mirror of local `main`
- State/cache location: provider-local cache only
- Diagnostic: `mcp:github:whoami`
- Baseline scopes: read issues, pull requests, repository metadata, Actions logs
- Elevated scopes: create repo, set mirror-oriented repo settings, trigger
  workflow, or push `main` only when explicitly needed; create PRs, issues,
  projects, or remote-only branches only when the operator opts into
  collaboration mode
- Risk rating: medium
- Audit expectations: token scope must be repo-limited; record write actions in handoff
- Failure fallback: `gh` CLI mirror flow or web browser

## Optional app-scoped servers

### browser-ui-smoke

- Name: browser-ui-smoke
- Purpose: run local UI smoke checks, screenshots, and interaction probes
- Command or URL: browser automation MCP selected by the app
- Environment schema: local browser/profile settings only
- Isolation boundary: localhost app URL and app-specific browser profile
- State/cache location: app-specific browser profile/cache
- Diagnostic: open the app's local health or home route
- Baseline scopes: local browser read/interact
- Elevated scopes: none outside the app's local URL
- Risk rating: medium
- Audit expectations: do not reuse a browser profile with logged-in state from another app
- Failure fallback: Playwright/Cypress/browser CLI configured by the app

### sqlite-inspector

- Name: sqlite-inspector
- Purpose: inspect app-local SQLite schema and development data
- Command or URL: local SQLite MCP selected by the app
- Environment schema: repo-local database path
- Isolation boundary: database file under this app repo or app-specific data directory
- State/cache location: none beyond the database file
- Diagnostic: `SELECT 1`
- Baseline scopes: read-only
- Elevated scopes: migrations or writes only through app-approved commands
- Risk rating: medium
- Audit expectations: never point at a sibling app database
- Failure fallback: `sqlite3`

### postgres-inspector

- Name: postgres-inspector
- Purpose: query running PostgreSQL database for schema and data verification
- Command or URL: local or containerized MCP
- Environment schema: `PG_URL` (read-only credentials required)
- Isolation boundary: app-specific database, schema, or container network
- State/cache location: database server only
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
- Isolation boundary: app-specific Redis DB index or key prefix
- State/cache location: Redis server only
- Diagnostic: `mcp:redis:info`
- Baseline scopes: read-only (GET, INFO, KEYS)
- Elevated scopes: write access (FLUSHDB)
- Risk rating: medium
- Audit expectations: ensure no sensitive keys are leaked
- Failure fallback: redis-cli

### observability-inspector

- Name: observability-inspector
- Purpose: inspect app-local logs, traces, metrics, or dashboards
- Command or URL: local or hosted MCP selected by the app
- Environment schema: provider token if required, not stored here
- Isolation boundary: app-specific telemetry source only
- State/cache location: provider-local cache only
- Diagnostic: app-specific health/log query
- Baseline scopes: read-only
- Elevated scopes: none by default
- Risk rating: medium
- Audit expectations: avoid exporting secrets or cross-app telemetry
- Failure fallback: local logs, dashboard UI, or provider CLI

### memory-artifact-store

- Name: memory-artifact-store
- Purpose: persist app-specific agent memory or generated artifacts when repo files are insufficient
- Command or URL: local or hosted MCP selected by the app
- Environment schema: app namespace and token if required, not stored here
- Isolation boundary: app namespace only
- State/cache location: app namespace or app-local artifact directory
- Diagnostic: write/read a non-secret test artifact in the app namespace
- Baseline scopes: app-local read/write
- Elevated scopes: cross-app lookup is forbidden unless the operator explicitly authorizes it
- Risk rating: high
- Audit expectations: prefer `_system/context/` first; record external memory usage
- Failure fallback: `_system/context/` and top-level handoff files
