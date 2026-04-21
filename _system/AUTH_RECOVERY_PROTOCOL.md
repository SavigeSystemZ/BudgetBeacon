# Authentication Recovery Protocol

This protocol provides the definitive recovery steps for authentication and authorization failures within the AIAST Swarm Fleet.

## 1. SSH Authentication Failures (GitHub)
**Problem:** `git push` or `ssh -T git@github.com` fails with "Permission denied (publickey)."

### Diagnostic
```bash
ssh -vT git@github.com
```

### Recovery (Run as elevated or root if needed, but TARGET is 'whyte')
1. Ensure the SSH agent is running and has the keys:
   ```bash
   sudo -u whyte -H bash -lc 'ssh-add -l'
   ```
2. If no keys are loaded, restart the agent and add them:
   ```bash
   sudo -u whyte -H bash -lc 'eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_ed25519'
   ```
3. Verify ownership of the `.git` directory:
   ```bash
   sudo chown -R whyte:whyte .git
   ```

## 2. MCP Server Authentication
**Problem:** MCP tool calls fail with "Unauthorized" or "Token Expired."

### GitHub MCP Recovery
1. Regenerate your Personal Access Token (PAT) on GitHub.
2. In Cursor/Windsurf settings, update the `GITHUB_PERSONAL_ACCESS_TOKEN` environment variable for the GitHub MCP server.
3. Restart the MCP server in the IDE.

### Brave Search MCP Recovery
1. Verify API usage limits at `api.search.brave.com`.
2. Update the `BRAVE_API_KEY` in your IDE settings.

## 3. IDE Memory/Agent "Looping"
**Problem:** Agent is stuck in a logic loop or fails to recognize the project context.

### Recovery
1. Run the Swarm Repair Tool:
   ```bash
   zsh ./TEMPLATE/bootstrap/repair-swarm-integrity.sh --reset-agent-state
   ```
2. This will prune `.cursor/rules/.state` and force a fresh context reload.

## 4. Sub-Agent Handoff Failures
**Problem:** Sub-agent (auxiliary CLI) fails to complete a task or stops responding.

### Recovery
1. The primary orchestrator must "Reclaim" the task.
2. Rename the sub-agent's working branch to `ai/reclaimed/<feature>`.
3. Read the sub-agent's last `PLAN.md` heartbeat and document the failure in `WHERE_LEFT_OFF.md`.
