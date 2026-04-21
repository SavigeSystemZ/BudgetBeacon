# Context State

This folder holds durable working context that should survive tool swaps and session resets.

## Files

- `CURRENT_STATUS.md` — the current operating reality
- `DECISIONS.md` — durable decisions and why they were made
- `MEMORY.md` — stable preferences, conventions, and constraints
- `ARCHITECTURAL_INVARIANTS.md` — hard rules that should rarely change
- `ASSUMPTIONS.md` — active assumptions still waiting for proof
- `INTEGRATION_SURFACES.md` — external systems and contracts that shape the repo
- `OPEN_QUESTIONS.md` — unresolved decisions that matter
- `QUALITY_DEBT.md` — known quality gaps that are real but not blocking

## Rule

Do not turn these files into noisy session dumps. Keep them high-signal and durable.

In the AIAST source repo, maintainer-only template-evolution context belongs in the master-repo-only meta workspace instead of these installable context files.
