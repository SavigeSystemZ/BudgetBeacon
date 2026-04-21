---
name: debug-playbook
description: Use when a build, test, runtime, packaging, or install flow fails.
---

# Debug Playbook

## Steps

### 1. Reproduce the failure exactly

- Run the exact failing command. Copy the full error output.
- Note the environment: OS, runtime version, dependency versions.
- Confirm: does it fail consistently, or is it intermittent?
- If intermittent, identify conditions that make it more likely (timing, data, concurrency).

### 2. Narrow the failing surface

Use binary search to isolate the failure:

- **If a test fails**: Does it fail in isolation (`test.only`)? Does it pass with a different fixture?
- **If a build fails**: Does it fail on a specific file? Comment out imports to find the trigger.
- **If runtime fails**: Does the error point to a specific function? Add boundary logging above and below the crash site.
- **If it worked before**: Use `git bisect` or manual commit checkout to find the breaking change.

Goal: reduce the problem from "something is broken" to "this specific line/module/input causes the failure."

### 3. Form a hypothesis

State it explicitly: "I believe X is happening because Y, and if I do Z, the error should change in this way."

Common root cause patterns:
- **Type mismatch**: wrong shape passed to a function or API.
- **Missing dependency**: package not installed, wrong version, peer dependency conflict.
- **Stale state**: cached build, stale lock file, outdated generated code.
- **Environment drift**: works locally, fails in CI; works on Node 20, fails on Node 18.
- **Race condition**: async operations completing in unexpected order.
- **Import/path error**: wrong relative path, case-sensitivity issue, missing file extension.

### 4. Apply the smallest correct fix

- Fix only the root cause. Do not refactor surrounding code.
- If the fix requires a workaround, document why the proper fix is deferred.
- Verify the hypothesis: the fix should resolve the error for the reason you predicted, not by accident.

### 5. Add regression coverage

- Write a test that would have caught this failure before the fix.
- If the bug was in a critical path, add it to the smoke test suite.
- If a test already existed but didn't catch it, investigate why and strengthen it.

### 6. Re-run the validation ladder

- Run the full validation tier appropriate to the change (see `_system/VALIDATION_GATES.md`).
- Confirm no new failures were introduced.
- If new failures appear, treat them as a separate debug cycle — do not conflate fixes.

Reference `_system/DEBUG_REPAIR_PLAYBOOK.md` for the full repair protocol.

## Output

- root cause (specific mechanism, not just symptom)
- fix summary (what changed and why)
- files changed
- commands run (with output)
- regression test added (or why not)
- remaining risk
- rollback note (how to undo the fix if it causes problems)
