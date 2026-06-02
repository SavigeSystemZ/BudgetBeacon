# Downstream Apply/Rollback Drill Protocol

This protocol defines simulation-only rehearsal for downstream template rollout.

## Drill Modes

- `plan`: enumerate deterministic target order and dry-run commands only.
- `apply-simulated`: run downstream `update-template.sh` in `--dry-run` mode and
  record simulated apply results.
- `rollback-simulated`: emit rollback command plan per target without executing
  destructive rollback commands.

## Safety Guardrails

- Real rollback actions are never executed by rehearsal scripts.
- Any rollback command output is advisory and requires explicit operator approval.
- Rehearsal output must include auditable target ordering and per-target records.

## Evidence Requirements

- Markdown evidence report under `_META_AGENT_SYSTEM/evidence/`.
- JSON summary output in `--json` mode containing:
  - drill `mode`
  - report `output` path
  - per-target `results` objects
