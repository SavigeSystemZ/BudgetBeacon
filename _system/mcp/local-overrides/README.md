# MCP Local Overrides

This directory holds **host-absolute MCP configuration** that must never
be tracked in git. The companion `.gitignore` excludes everything in
this directory except this README and the `.gitignore` itself.

## What goes here

- Resolved absolute paths for host adapters that require them (e.g. a
  filesystem MCP server expecting an absolute project root in its
  config).
- Per-instance credentials sourced from a local secret manager.
- Anything `bootstrap/check-mcp-project-isolation.sh` flags as a
  "forbidden tracked root" or "forbidden tracked secret" when it lives
  in `_system/mcp/servers.*.example.*`.

## What does NOT go here

- Reusable, template-safe MCP configuration. That belongs in
  `_system/mcp/servers.<adapter>.example.<ext>` with placeholders such
  as `__AIAST_PROJECT_ROOT__`, `${AIAST_PROJECT_ROOT}`, or
  `${workspaceFolder}` — see `_system/mcp/MCP_PROJECT_ISOLATION_POLICY.md`.
- Instance registry records — those live under `_system/mcp/instances/`
  and are tracked.
- Long-lived secrets that should be in your OS keychain.

## Verification

`bootstrap/check-mcp-project-isolation.sh` runs `git check-ignore` on
every file here to confirm the .gitignore is doing its job. Any file
that is **not** ignored is treated as a tracked-secret risk and
refused under the `strict` validation profile.

## Related

- `_system/mcp/MCP_PROJECT_ISOLATION_POLICY.md`
- `_system/mcp/MCP_INSTANCE_REGISTRY_PROTOCOL.md`
- `_system/mcp-instance-policy.json` (`registry.local_overrides_dir`)
