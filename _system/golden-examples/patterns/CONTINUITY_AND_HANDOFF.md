# Continuity And Handoff Pattern

## Use when

- a repo keeps losing context quality between sessions
- `WHERE_LEFT_OFF.md`, `PLAN.md`, or `TODO.md` drift into vague notes
- agents need a stronger resume path after context reset

## Primary donors

- CandleCompass
- LedgerLoop

## What to emulate

- a compact session snapshot with current phase, branch, confidence, and next-best-step
- explicit validation evidence, including command names and honest outcomes
- durable separation between active queue, unresolved risk, and long-lived context
- handoff packets that tell the next agent what changed, what was verified, and what remains blocked

## What not to inherit

- donor-domain vocabulary
- giant transcript-style memory dumps
- stale milestone details that no longer match the repo

## Adoption checklist

1. Keep `WHERE_LEFT_OFF.md` short, factual, and resumable.
2. Put active execution in `PLAN.md`, not in chat.
3. Record discovered work in `TODO.md` before handoff.
4. Move durable facts into `_system/context/` instead of repeating them everywhere.
5. Include validation commands and outcomes every time meaningful work lands.
