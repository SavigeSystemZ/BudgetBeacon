# Self-Writing Boundary and Rollback

This contract bounds **project-local self-writing**: an agent improving its own
project-local AIAST copy under `PROJECT_LOCAL_SELF_IMPROVEMENT_PROTOCOL.md`.

Self-writing is distinct from **self-healing**. `SELF_HEALING_BOUNDARY.md`
covers conservative *mechanical repair* of known drift. Self-writing is
*additive improvement* of the local operating layer. Both are bounded; neither
may erase repo-owned truth or cross a repo boundary.

## Write-scope rule (hard)

A self-writing change may write **only inside the current repo root**.

- The active repo is resolved from the working directory and
  `_system/.aiast-role.json`.
- Any target path that resolves outside the repo root is refused — not warned,
  refused — by `bootstrap/apply-local-self-improvement.sh`.
- Self-writing never runs in `parent-template` mode.

This is enforced under `WORKSPACE_AUTHORITY_AND_CONTAINMENT_PROTOCOL.md`
(downstream project mode: only the active repo is writable).

## Improvement classes

### Allowed (apply, validate, record)

- add or fill app-specific context files (`APP_CONTEXT_FILE_MATRIX.md`);
- fill `_system/PROJECT_PROFILE.md` and `_system/context/*` working files;
- add a local validation profile for this app's stack;
- add local prompt-pack variants for this app's domain;
- add local MCP / agent-isolation notes for this app;
- add local installer / runbook detail;
- add local archetype notes;
- improve local handoff / checkpoint quality;
- tag a generic improvement as a candidate.

### Guarded (allowed, but require validation evidence before handoff)

- modify local bootstrap scripts;
- modify local validation scripts;
- modify local security rules;
- modify local MCP config examples;
- modify local agent adapter files;
- change the local scaffold-profile selection.

A guarded change must re-run the owning validator and record the result in the
proposal before the session ends.

### Forbidden without explicit operator approval

- write the parent AIAST template (`~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/`);
- write sibling app repos;
- write global / home tool memory;
- write global MCP configuration or system config;
- commit secrets or credentials;
- overwrite `.env`;
- delete user data;
- rewrite runtime app architecture silently;
- modify runtime app code outside the change's declared scope;
- promote app-specific facts into the parent template.

A forbidden action is not unblocked by self-improvement. It needs an explicit,
specific operator instruction, and even then stays governed by the relevant
containment and security contracts.

## Rollback discipline

Every applied self-improvement must be reversible:

1. Before writing, `apply-local-self-improvement.sh` records the base commit
   SHA and a reverse patch into the `applied/` record.
2. To roll back: restore the changed paths from the base commit
   (`git checkout <base-sha> -- <paths>`) or apply the reverse patch, then move
   the proposal record to `_system/self-improvement/rejected/` with the reason.
3. Re-run validation after rollback and record the real outcome.

If a change cannot be cleanly reverted, it was too large — split it.

## Bounded apply loop

1. Apply only the smallest change the proposal describes.
2. Re-run the owning validator immediately.
3. Record command + result evidence.
4. If validation still fails after two attempts, roll back and escalate to the
   operator. Do not keep retrying a failing self-write.

## Enforcement

- `bootstrap/apply-local-self-improvement.sh` — write-scope and role guard;
  refuses any path resolving outside the repo and refuses `parent-template`.
- `bootstrap/check-local-self-improvement.sh` — audits that applied changes
  stayed in-repo and the ledger is intact.
- `_system/policy-contracts/self-writing-boundary.json` — asserts this contract
  still states its forbidden-write rules and that the apply guard is present.
- `bootstrap/system-doctor.sh` — surfaces the check as a warn-tier signal.

---
**Authority:** AIAST containment contract. Subordinate to
`INSTRUCTION_PRECEDENCE_CONTRACT.md`,
`WORKSPACE_AUTHORITY_AND_CONTAINMENT_PROTOCOL.md`, and the security contracts.
**Related:** `PROJECT_LOCAL_SELF_IMPROVEMENT_PROTOCOL.md`,
`SELF_HEALING_BOUNDARY.md`, `TEMPLATE_NEUTRALITY_POLICY.md`.
