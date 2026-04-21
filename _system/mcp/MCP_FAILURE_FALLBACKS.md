# MCP Failure Fallbacks

## When a server fails

1. note the failure once
2. identify whether the task truly depends on that server
3. continue with repo context if it does not
4. document the dependency in `PROJECT_PROFILE.md` if the failure blocks critical work

## Common fallbacks

- filesystem MCP -> native shell or built-in tooling
- doc lookup MCP -> repo docs and official docs lookup
- memory MCP -> repo continuity files under `_system/context/` and top-level handoff files
- observability MCP -> local logs, reports, or documented manual workflow
