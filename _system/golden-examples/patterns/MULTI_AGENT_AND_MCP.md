# Multi-Agent And MCP Pattern

## Use when

- defining handoff, turn-taking, or subagent scope rules
- deciding how MCP tools should be selected, constrained, or bypassed
- making a repo resilient when tools differ or fail

## Primary donors

- curated-donor

## What to emulate

- explicit single-writer discipline
- clear role boundaries for parallel or sequential agents
- MCP fallback behavior that preserves momentum when tools are unavailable
- read-only defaults with deliberate elevation rules

## What not to inherit

- mandatory MCP dependencies for ordinary coding tasks
- token-bearing repo configs
- ambiguous shared ownership over the same files

## Adoption checklist

1. Define the shared core before defining tool overlays.
2. Keep MCP server selection tied to task value and least privilege.
3. Spell out what happens when an MCP is missing or broken.
4. Preserve repo-local continuity so the next tool can resume without chat-only memory.
