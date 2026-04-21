# MCP Survival Playbook

This document defines the diagnostic, repair, and re-authentication protocols for every MCP server in the Swarm Fleet. If a server fails, follow these steps to restore connectivity or transition to a contingency state.

## 1. Core Survival Checklist

| Symptom | Action | Recovery Target |
| :--- | :--- | :--- |
| **Tool Call Failure** | Ping Command | Diagnostic |
| **"Unauthorized"** | Clear Token / Re-Auth | Authentication |
| **"Server Hung"** | Kill Process / Restart IDE | Runtime |
| **Hard Fail** | Fallback to Native Tooling | Contingency |

## 2. Server-Specific Diagnostics & Recovery

### project-filesystem
- **Diagnostic:** `ls TEMPLATE/_system/`
- **Failure:** Tool returns "Path not found" or "Access denied."
- **Recovery:** 
  1. Ensure the server is restricted to the current project root.
  2. Verify directory permissions: `sudo chown -R whyte:whyte .`
- **Fallback:** Use native terminal `ls`, `grep`, `find`, and `cat`.

### github-actions-monitor (or @modelcontextprotocol/server-github)
- **Diagnostic:** `gh auth status` or `mcp:github:whoami`
- **Failure:** "Token expired" or "401 Unauthorized."
- **Recovery:**
  1. Regenerate GitHub PAT (fine-grained, repo-only scope).
  2. Update IDE MCP environment variable `GITHUB_PERSONAL_ACCESS_TOKEN`.
  3. Restart MCP server.
- **Fallback:** Web browser at `github.com/<org>/<repo>/actions`.

### postgres-inspector
- **Diagnostic:** `mcp:postgres:query "SELECT 1"`
- **Failure:** "Connection refused" or "Authentication failed."
- **Recovery:**
  1. Verify the PG container is running: `docker ps | grep postgres`.
  2. Test `PG_URL` manually: `psql $PG_URL -c "SELECT 1"`.
  3. Update IDE MCP `PG_URL` settings.
- **Fallback:** Manual `psql` shell as `whyte` or `sudo -u postgres`.

### brave-search-monitor
- **Diagnostic:** `mcp:brave-search:search "AIAST Swarm"`
- **Failure:** "API Key Invalid" or "Rate Limit Exceeded."
- **Recovery:**
  1. Verify API key usage at `api.search.brave.com`.
  2. Update IDE MCP `BRAVE_API_KEY`.
- **Fallback:** Native web browser research.

## 3. Resilience Enforcement
- **Heartbeat:** All auxiliary workers MUST report MCP connectivity status in their initial turn.
- **Auto-Reauth:** If an agent detects an expired token, it MUST pause and provide the human operator (`whyte`) with the exact re-auth command from `_system/AUTH_RECOVERY_PROTOCOL.md`.
- **No-Stall Rule:** Do not wait more than 1 turn for an MCP server to respond. If it hangs, trigger the fallback immediately and document the issue.
