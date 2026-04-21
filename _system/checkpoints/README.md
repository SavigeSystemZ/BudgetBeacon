# `_system/checkpoints/`

Agent-neutral mid-session resume surface. Any agent — Claude, Codex, Cursor,
Gemini, Windsurf, DeepSeek, Cline, Continue, Aider, PearAI, local models, or a
human — writes and reads checkpoints here so that rate limits, crashes, and
compactions never destroy continuity.

## Files

```
_system/checkpoints/
  README.md          # You are here
  LATEST.json        # Most recent checkpoint, machine-readable (overwritten)
  LATEST.md          # Most recent checkpoint, human-readable (overwritten)
  history/
    <ts>-<kind>.json # Append-only history, one file per checkpoint
```

`LATEST.json` and `LATEST.md` are rewritten atomically (tempfile + rename) by
every checkpoint write. The `history/` directory is append-only; never edit
existing history files — write a new checkpoint instead.

## How to write a checkpoint

```bash
bash bootstrap/write-checkpoint.sh . \
  --agent claude \
  --kind mid-task \
  --phase "What you're working on" \
  --next  "First next step" \
  --next  "Second next step" \
  --resume-file WHERE_LEFT_OFF.md \
  --resume-command "Continue from step 1 after reading WHERE_LEFT_OFF.md" \
  --confidence medium
```

See `_system/CHECKPOINT_PROTOCOL.md` for the full flag set, the five checkpoint
kinds (`session-start`, `mid-task`, `handoff`, `rate-limit-save`, `milestone`),
required fields, and the rules for honest validation reporting.

## How to read a checkpoint on cold start

```bash
bash bootstrap/resume-from-checkpoint.sh .
```

Prints a concise human briefing built from `LATEST.json`. Other formats:

```bash
bash bootstrap/resume-from-checkpoint.sh . --format json   # raw payload
bash bootstrap/resume-from-checkpoint.sh . --format md     # pre-rendered
bash bootstrap/resume-from-checkpoint.sh . --history       # list all past
```

Exit codes: `0` briefing printed, `3` no checkpoint yet, `4` LATEST.json
is malformed.

## Rules

- **Never** commit secrets, credentials, API keys, or PII into a checkpoint.
  Treat every field as world-readable within this repo.
- **Never** claim validation that was not actually run. If the command was not
  run or failed, record it exactly that way.
- **Prefer** small, frequent checkpoints (every 5–10 minutes of real work).
  A cheap `mid-task` save beats a rich end-of-session one that never happens
  because the agent was interrupted first.
- **Before** any command that could exhaust the remaining token/time budget,
  write a `rate-limit-save` checkpoint. Prioritize correctness of
  `next_actions` over polish.
- **Every** agent must write a checkpoint before stopping for any reason.

## Relationship to other resume surfaces

| Surface                                | Cadence         | Purpose                                      |
|----------------------------------------|-----------------|----------------------------------------------|
| `_system/checkpoints/LATEST.*`         | Many per session | Mid-session crash/rate-limit safety net      |
| `WHERE_LEFT_OFF.md`                    | Session end      | Stable, reviewable session handoff           |
| `_system/context/CURRENT_STATUS.md`    | Session end      | Rolling project status snapshot              |
| `_system/HANDOFF_PROTOCOL.md`          | —                | Governance of session-end handoff            |
| `_system/CHECKPOINT_PROTOCOL.md`       | —                | Governance of mid-session checkpointing      |

On a clean stop, both a checkpoint and `WHERE_LEFT_OFF.md` should be written.
The checkpoint is the finer-grained of the two and wins when they disagree
because it is newer.
