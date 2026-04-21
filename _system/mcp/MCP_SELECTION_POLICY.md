# MCP Selection Policy

Choose the smallest server set that materially improves work on the project.

## Baseline set

- project filesystem
- doc lookup

## Add only when justified

- database diagnostics
- git metadata
- memory/artifact servers
- issue tracker or observability tooling

## Do not add by default

- broad mutation-capable servers with unclear need
- servers that require secrets inside repo-tracked config
- servers with wildcard or omnibus scopes
