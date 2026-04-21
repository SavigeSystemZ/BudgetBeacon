# Debug Repair Playbook

Use this whenever something fails or regresses.

## Output format

- root cause
- fix summary
- files changed
- validation commands
- risk and rollback note
- checkpoint status

## Step 1: Triage

Classify the failure:

- build or import failure
- runtime crash
- wrong output or logic bug
- UI regression
- performance regression
- flaky behavior
- environment or permission mismatch

## Step 2: Reproduce

- capture exact commands and inputs
- record expected vs actual behavior
- preserve relevant logs, traces, or screenshots

Rule: no fix without a reproduction path or a stated reason reproduction is not possible.

## Step 3: Localize

- reduce to the smallest failing surface
- identify last known-good behavior if possible
- add temporary instrumentation only if it helps isolate the issue

## Step 4: Hypothesis loop

- make the smallest experimental change
- verify locally first
- expand verification only after the local result is promising

## Step 5: Fix

- choose the smallest correct fix
- if refactor is required, separate it from behavior change
- add regression coverage where appropriate

## Step 6: Verification ladder

1. lint or typecheck
2. unit or targeted tests
3. feature or integration checks
4. build or smoke checks
5. perf sanity check if relevant

## Step 7: Finish

- remove temporary instrumentation if it is no longer needed
- update handoff docs
- run checkpoint flow if the fix crossed an important boundary
