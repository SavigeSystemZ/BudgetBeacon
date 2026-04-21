# Hallucination Defense Protocol

Hallucination in this system means claiming a file, state, validation result, integration, or recovery status that the repo does not prove.

## Common hallucination patterns

- claiming validation without commands or artifacts
- referring to files or surfaces that do not exist
- presenting stale working files as current truth
- claiming completion while blocker or confidence surfaces say otherwise
- inferring runtime or deploy behavior from templates without real verification

## Defense rules

- Verify before claiming.
- Prefer concrete file paths, commands, and outputs over narrative confidence.
- If confidence is high, the latest passing validation must be recorded.
- If a release or recovery claim is made, operator-facing evidence must exist.
- If docs contradict each other, stop and repair the operating picture first.

## Commands

- `bootstrap/check-hallucination.sh <repo>`
- `bootstrap/check-evidence-quality.sh <repo>` — scan handoff files for ungrounded claims
- `bootstrap/check-working-file-staleness.sh <repo>` — detect stale handoff surfaces
- `bootstrap/check-system-awareness.sh <repo>`
- `bootstrap/system-doctor.sh <repo>`

## Recovery flow

1. Run `bootstrap/system-doctor.sh <repo>`.
2. If the system layer is broken, run `bootstrap/heal-system.sh <repo> --source <template-root>`.
3. Regenerate the system registry if AIAST-managed files changed.
4. Repair working-file contradictions before resuming broad implementation.
