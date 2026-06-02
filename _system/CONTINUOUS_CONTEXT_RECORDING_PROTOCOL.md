# Continuous Context Recording Protocol

Checkpointing is mandatory and continuous for meaningful work.

## Required Event Types

- `session-start`
- `task-accepted`
- `scope-claimed`
- `file-read`
- `file-edited`
- `command-run`
- `test-pass`
- `test-fail`
- `decision-made`
- `checkpoint-written`
- `handoff-written`
- `validation-attached`
- `scope-released`
- `session-end`

## Required Surfaces

- `_system/context/EVENT_TIMELINE.md`
- `_system/context/BUILD_LOG.md`
- `_system/context/DECISION_LEDGER.md`
- `_system/context/VALIDATION_EVIDENCE.md`
- `_system/context/events.jsonl`

## Cadence

- At each meaningful edit.
- Before and after risky operations.
- At least every 5-10 minutes for long sessions.
- Before stopping or handoff.

## Scripts

- `bootstrap/record-agent-event.sh`
- `bootstrap/append-build-log.sh`
- `bootstrap/check-context-freshness.sh`

