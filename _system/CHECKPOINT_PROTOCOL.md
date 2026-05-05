# Checkpoint Protocol

This protocol is how any agent — Claude, Codex, Cursor, Gemini, Windsurf,
DeepSeek, Cline, Continue, Aider, PearAI, local models, or a human — hands
off in-flight work to whoever resumes next. It is optimized for the hostile
cases: rate-limit interruptions, crashes, mid-task context compactions, and
cold starts by a fresh agent that has zero prior session memory.

Checkpoints live on disk under `_system/checkpoints/` and are written and
read by these two agent-neutral scripts:

- `bootstrap/write-checkpoint.sh` — writes `_system/checkpoints/LATEST.json`
  plus `_system/checkpoints/LATEST.md` and appends to
  `_system/checkpoints/history/<ts>-<kind>.json`
- `bootstrap/resume-from-checkpoint.sh` — prints a concise resume briefing
  from `LATEST.json` for the next agent to paste into its own startup

`WHERE_LEFT_OFF.md` and `_system/context/CURRENT_STATUS.md` remain the
session-end handoff surfaces (see `_system/HANDOFF_PROTOCOL.md`).
Checkpoints are the **mid-session** surface that exists on top of those,
so an interrupted agent never loses more than its most recent checkpoint
interval's worth of progress.

## Goals

- **Survive rate limits and crashes.** The next agent should be able to
  resume from the last checkpoint without re-deriving state from chat
  history that no longer exists.
- **Stay agent-neutral.** Every field is plain text or JSON; no
  vendor-specific payload. Any agent CLI can read `LATEST.md`.
- **Leave a clean resumption point.** The next agent gets an ordered
  next-actions list, the resume files to load, and a concrete resume
  command.
- **Keep changes reviewable.** History is append-only; `LATEST.*` is
  overwritten atomically.
- **Require no new dependencies.** Only `bash` and `python3` (already
  required by the rest of the AIAST bootstrap layer).

## Checkpoint kinds

| Kind              | When to write it                                                                 |
|-------------------|----------------------------------------------------------------------------------|
| `session-start`   | First thing any agent does after reading the resume briefing on cold start.     |
| `mid-task`        | After each meaningful step (file edits saved, command run, test passed/failed).  Target cadence: at least once every 5–10 minutes of real work. |
| `handoff`         | When explicitly handing off between agents or between agent and human.           |
| `rate-limit-save` | **Before** running any command that could exhaust the remaining token/time budget, and **immediately** when the harness warns of an upcoming limit. Prioritize correctness of `next_actions` over polish. |
| `milestone`       | Milestone completion, risky refactor landing, design direction shift, install/launch/packaging change, or release-path change. Pair with a `CHANGELOG.md` or `RELEASE_NOTES.md` update. |

**Every agent must write a checkpoint before stopping, regardless of
reason.** That includes voluntary stops ("I'm done"), forced stops (rate
limit, crash, timeout), and mid-turn context compactions where the agent
knows its memory of the session is about to be summarized away.

## Required fields for a usable checkpoint

The resume briefing degrades gracefully, but a checkpoint with only a
timestamp is not usable. Every checkpoint should set at least:

- `kind` — one of the kinds above
- `agent` — who wrote it (lowercase identifier, e.g. `claude`, `codex`, `cursor`)
- `phase` — one short phrase ("Refactoring auth middleware")
- `next_actions` — at least one concrete next step
- `resume_files` — the minimal file set the next agent must load
- `resume_command` — a plain-English instruction for the next agent
- `confidence` — `high`, `medium`, or `low`

Add `completed_steps`, `in_progress_step`, `blockers`, `validation_state`,
and `notes` when they are known. An under-specified checkpoint is still
better than no checkpoint — the goal is forward progress, not perfection.

## Writing a checkpoint

The minimum viable rate-limit save:

```bash
bash bootstrap/write-checkpoint.sh . \
  --agent claude \
  --kind rate-limit-save \
  --phase "AIAST 1.23.0 downstream replay on <ProjectX>" \
  --completed "Ran update-template.sh --refresh-managed --strict" \
  --in-progress "Refreshing <ProjectX> WHERE_LEFT_OFF.md" \
  --next "Finish WHERE_LEFT_OFF.md refresh" \
  --next "Run system-doctor.sh" \
  --next "Commit and push" \
  --resume-file "WHERE_LEFT_OFF.md" \
  --resume-file "_system/context/CURRENT_STATUS.md" \
  --resume-command "Continue <ProjectX> 1.23.0 replay from the WHERE_LEFT_OFF.md refresh step, then run system-doctor.sh and commit." \
  --confidence medium
```

A richer milestone checkpoint that records a passing validation:

```bash
bash bootstrap/write-checkpoint.sh . \
  --agent codex \
  --kind milestone \
  --phase "Shipped checkpointing capability" \
  --completed "Added bootstrap/write-checkpoint.sh and resume-from-checkpoint.sh" \
  --completed "Wired _system/checkpoints/ into MASTER_SYSTEM_PROMPT and SYSTEM_AWARENESS_PROTOCOL" \
  --next "Cut minor release with checkpointing slice" \
  --resume-file "_system/CHECKPOINT_PROTOCOL.md" \
  --validation-command "bash bootstrap/validate-system.sh . --strict" \
  --validation-result "system_ok" \
  --validation-run-at "2026-04-13T21:00:00Z" \
  --confidence high
```

You can also build a checkpoint payload as a JSON file and then point
`--from-json` at it:

```bash
bash bootstrap/write-checkpoint.sh . --from-json /tmp/my-checkpoint.json
```

Flag values always override matching keys from the loaded JSON, so you
can use `--from-json` as a base template and layer freshness on top.

## Reading a checkpoint

On cold start, before loading anything else, the resuming agent runs:

```bash
bash bootstrap/resume-from-checkpoint.sh .
```

Output is a plain-text briefing: kind, agent, phase, completed steps,
in-progress step, ordered next actions, blockers, resume files, resume
command, and validation state. Paste or summarize this at the top of the
first turn, then start work on the first next action.

Machine consumers can use:

```bash
bash bootstrap/resume-from-checkpoint.sh . --format json | jq .next_actions
bash bootstrap/resume-from-checkpoint.sh . --format md         # pre-rendered
bash bootstrap/resume-from-checkpoint.sh . --history           # every past checkpoint
bash bootstrap/resume-from-checkpoint.sh . --json-path         # just the path
```

Exit codes: `0` briefing printed (or path returned), `3` no checkpoint
exists, `4` LATEST.json is malformed.

## Placement and file layout

```
_system/checkpoints/
  README.md                             # Overview and rules for this directory
  LATEST.json                           # Latest checkpoint, machine-readable
  LATEST.md                             # Latest checkpoint, human-readable
  history/
    20260413T210533Z-mid-task.json      # Append-only history
    20260413T212115Z-rate-limit-save.json
    ...
```

`LATEST.*` is overwritten atomically (tempfile + rename). History files
are written once and never modified. Do **not** rewrite history files by
hand; write a new checkpoint instead.

## Rules

- **Never** commit secrets, machine-local credentials, raw API keys, or
  user PII into a checkpoint. The checkpoint is intentionally a plain-text
  file that any agent may read; treat it as public within the repo.
- **Never** claim `validation_state` fields that were not actually run.
  The `validation_last_result` is evidence — if the command was not run
  or did not pass, say so explicitly ("not run", "fail: <reason>").
- **Never** write a checkpoint that says "complete" when validation
  failed and the failure is undocumented.
- **Never** hand off partial work without saying exactly what remains.
  An empty `in_progress_step` with a non-empty `next_actions` is fine;
  a vague one like "continue the work" is not.
- **Prefer** small, frequent checkpoints. A checkpoint every 5–10 minutes
  of meaningful work gives the next agent far more continuity than one
  rich checkpoint at the end.
- **Prefer** specific resume files. `WHERE_LEFT_OFF.md` plus the single
  file being edited beats listing every file in the repo.

## Wiring into agent startup

Agents pick up checkpoints automatically because the following surfaces
reference `_system/checkpoints/LATEST.md` and
`bootstrap/resume-from-checkpoint.sh` as a startup step:

- `_system/MASTER_SYSTEM_PROMPT.md`
- `_system/SYSTEM_AWARENESS_PROTOCOL.md`
- `_system/CONTEXT_INDEX.md`
- `_system/LOAD_ORDER.md`

An agent that cannot run `bash` (rare on desktop agent CLIs) should still
open `_system/checkpoints/LATEST.md` directly and treat it as authoritative
for the current in-flight state.

## Relationship to WHERE_LEFT_OFF.md and HANDOFF_PROTOCOL.md

- `WHERE_LEFT_OFF.md` is the **session-end** resume packet. It is stable,
  reviewable, and gated by `_system/HANDOFF_PROTOCOL.md`.
- `_system/checkpoints/LATEST.*` is the **mid-session** snapshot. It
  changes many times per session and is optimized for rapid rewriting.
- On a clean stop, both should be written. The checkpoint is the
  finer-grained of the two and always wins when they disagree because
  it is newer.
- In the AIAST source repo, maintainer-only checkpoint state belongs in
  `_META_AGENT_SYSTEM/checkpoints/` instead of this installable surface.

## Stop conditions

- Do not checkpoint as `milestone` if validation failed and that failure
  is undocumented.
- Do not snapshot secrets or machine-local credentials.
- Do not hand off ambiguous partial work without saying exactly what
  remains.
- Do not let a session end without at least a `handoff` or `rate-limit-save`
  checkpoint.
