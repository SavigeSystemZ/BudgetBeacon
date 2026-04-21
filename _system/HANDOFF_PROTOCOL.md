# Handoff Protocol

This document specifies the quality requirements for agent-to-agent and agent-to-human handoffs.

## Why handoffs matter

A handoff is the single highest-leverage moment in multi-agent work. A bad handoff wastes the next agent's first 10 minutes reconstructing state. A good handoff lets the next agent begin productive work within seconds.

## Required handoff surfaces

Every meaningful work session must update at least these files before stopping:

1. `WHERE_LEFT_OFF.md` — primary resume packet (always update)
2. `TODO.md` — active queue with new and completed items
3. `FIXME.md` — newly discovered bugs or debt (if any)

Update these when the session changed their domain:

4. `PLAN.md` — if the execution plan shifted
5. `TEST_STRATEGY.md` — if coverage or confidence changed
6. `RISK_REGISTER.md` — if delivery risk changed
7. `CHANGELOG.md` — if user-visible behavior changed
8. `_system/context/CURRENT_STATUS.md` — if operating reality shifted
9. `_system/context/DECISIONS.md` — if a durable decision was made

## WHERE_LEFT_OFF.md required fields

Every handoff must include all of these in `WHERE_LEFT_OFF.md`:

### Session Snapshot (required)
- **Current phase**: what milestone or delivery phase is active
- **Working branch or lane**: which git branch or delivery lane
- **Completion status**: what percentage or state (e.g., "3 of 5 endpoints done")
- **Resume confidence**: `high` (next agent can start immediately), `medium` (needs 5 min review), or `low` (significant context reconstruction needed)

### Last Completed Work (required)
- Concrete list of what was done, not vague summaries
- Bad: "Made progress on the API"
- Good: "Implemented GET /users, POST /users, DELETE /users/:id with validation. 6 pytest tests passing."

### Validation Run (required)
- **Command**: exact command(s) run
- **Result**: pass/fail with output summary
- **Scope**: what the validation covered and what remains unproven

### Next Best Step (required)
- The single most valuable next action, stated as a concrete instruction
- Bad: "Continue working on the feature"
- Good: "Implement PATCH /users/:id with partial-update semantics, then add integration tests for the auth middleware"

### Handoff Packet (required)
- **Agent**: which agent performed the work
- **Timestamp**: when the handoff was written
- **Objective**: what the session set out to do
- **Files changed**: list of files modified
- **Commands run**: key commands executed with results
- **Known blockers**: anything that could stop the next agent
- **Next best step**: matches the top-level next best step

## TODO.md required format

### Priority signals
Tasks must carry a priority signal so agents know what to work on first:

```markdown
## Current Priority
- [ ] CRITICAL: Deploy hotfix for auth bypass (blocks all users)
- [ ] HIGH: Implement rate limiting on /api/upload

## Next Queue
- [ ] MEDIUM: Add pagination to user list endpoint
- [ ] LOW: Update README with new API examples
```

Priority levels:
- **CRITICAL**: blocks users, breaks production, or creates security exposure
- **HIGH**: blocks the current milestone or other high-priority work
- **MEDIUM**: planned work that should happen this milestone
- **LOW**: improvement or cleanup that can wait

### Completion tracking
- Mark items `[x]` when done, not when "mostly done"
- Add discovered work during the session, even if low priority
- Move completed items to a `## Completed` section at session end

## Evidence standard

Handoff claims must be grounded. Specifically:

- "Tests pass" requires: command, count, and any skipped/failed
- "Build succeeds" requires: command and output confirmation
- "Validated" requires: command, result, and scope
- "Deployed" requires: environment, URL/address, and smoke result
- "Fixed" requires: reproduction, fix description, and verification

If a check was not run, say "not verified" instead of omitting it.

## Auxiliary (host CLI) handback to primary

When a **separate** terminal or tool did work under `_system/SUB_AGENT_HOST_DELEGATION.md`:

- The auxiliary posts: scope honored, files touched, commands run, blockers.
- The **primary** records merge decisions in `WHERE_LEFT_OFF.md`, runs validation, and updates
  `TODO.md` / `FIXME.md` if the integrated work changed the queue.
- If auxiliary output is **rejected**, say so in the handoff packet (revert hash or reason).

Use `bootstrap/emit-auxiliary-brief.sh` to standardize the brief the auxiliary received.

## Anti-patterns

- Ending a session without updating WHERE_LEFT_OFF.md
- Writing "everything works" without validation evidence
- Leaving TODO.md with items marked complete that were only partially done
- Writing vague next steps like "continue the work" or "finish the feature"
- Omitting blockers or risks discovered during the session
- Updating WHERE_LEFT_OFF.md but leaving TODO.md stale (or vice versa)

## Staleness detection

Run `bootstrap/check-working-file-staleness.sh <repo>` to detect handoff surfaces that may be outdated. The script warns when:
- WHERE_LEFT_OFF.md hasn't been updated in the current git session
- TODO.md contains items marked as current priority with no recent activity
- PLAN.md references a phase that doesn't match WHERE_LEFT_OFF.md
