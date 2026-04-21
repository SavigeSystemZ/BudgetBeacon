Follow `_system/DEBUG_REPAIR_PLAYBOOK.md`.

## Process

1. **Reproduce**: Run the exact failing command. Copy the full error output. Note if it's consistent or intermittent.
2. **Narrow**: Use binary search — isolate the failing test, comment out imports, add boundary logging, or `git bisect` to find the breaking change. Goal: go from "something is broken" to "this specific line/input causes it."
3. **Hypothesize**: State it explicitly: "X is happening because Y." Common causes: type mismatch, missing dependency, stale cache/build, environment drift, race condition, import path error.
4. **Fix**: Apply the smallest correct fix. Fix only the root cause. Do not refactor surrounding code in the same pass.
5. **Cover**: Write a regression test that would have caught this failure before the fix.
6. **Validate**: Re-run the full validation ladder. Confirm no new failures.

## Report

1. Root cause (specific mechanism, not just symptom)
2. Files changed (with rationale)
3. Commands run (with output)
4. Regression test added
5. Risk and rollback note
6. Whether a checkpoint is now required
