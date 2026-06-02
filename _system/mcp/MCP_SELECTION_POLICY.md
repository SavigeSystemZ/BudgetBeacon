# MCP Selection Policy

Choose the smallest server set that materially improves work on the current app
without granting access to sibling apps, the parent template, home directories,
or global mutable state.

## Baseline set

- project filesystem scoped to the current app repo root
- doc lookup for version-sensitive work
- fetch or browser-readable reference access when external sources are needed
- repo-scoped GitHub access when the app has a matching GitHub mirror remote

## Add only when justified

- database diagnostics with app-specific read-only credentials by default
- browser automation for local UI smoke tests and screenshots
- memory/artifact servers with an app namespace
- issue tracker or observability tooling with app-local scope

## Do not add by default

- broad mutation-capable servers with unclear need
- servers that require secrets inside repo-tracked config
- servers with wildcard, home-directory, sibling-app, parent-template, or omnibus scopes
- shared memory, cache, browser profile, or database servers without an app namespace

## Isolation gate

Before enabling a server, answer these in `_system/mcp/MCP_SERVER_CATALOG.md`:

1. Which app root, URL, database, repo, or namespace is the server allowed to use?
2. Which credentials does it receive, and are they read-only by default?
3. Where does it store cache, state, browser profiles, memory, or logs?
4. What native fallback replaces it if the server fails?

Run `bash bootstrap/check-mcp-project-isolation.sh .` after changing MCP
configuration, examples, catalog entries, or host adapter guidance.

For GitHub MCP, the allowed repo is the app's matching mirror only. The
default single-developer mode is local-authoritative `main` mirrored to
GitHub; do not add broad organization scopes, issue/project workflows, PR
automation, or branch-management scopes unless the operator explicitly
chooses a collaboration workflow.
