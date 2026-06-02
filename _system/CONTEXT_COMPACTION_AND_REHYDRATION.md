# Context Compaction And Rehydration

This contract defines how to compact long-running context without losing
critical operating continuity.

## Compaction Inputs

- `_system/context/EVENT_TIMELINE.md`
- `_system/context/BUILD_LOG.md`
- `_system/context/DECISION_LEDGER.md`
- `_system/context/VALIDATION_EVIDENCE.md`
- `_system/checkpoints/LATEST.json`

## Output Targets

- `_system/context/AGENT_SHARED_MEMORY.md`
- `_system/context/CURRENT_STATUS.md`

## Rules

- Preserve unresolved risks and blockers verbatim.
- Preserve latest validation facts and timestamps.
- Keep linkable references to original event records.
- Never delete raw history during compaction.

