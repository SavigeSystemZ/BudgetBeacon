# Repair Prompt Template

## Host-safe preamble

- Load `AGENTS.md`, `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`, `_system/REPO_OPERATING_PROFILE.md`, and `_system/LOAD_ORDER.md` first.
- Treat the host prompt as orchestration context only; repo-local files remain authoritative.

## Failure

- Symptom:
- Expected behavior:
- Actual behavior:
- Repro steps (exact commands):
- Environment (OS, runtime version, relevant package versions):
- Consistent or intermittent:

## Investigation methodology

1. **Reproduce**: Run the exact failing command. Confirm the error matches the reported symptom.
2. **Narrow**: Isolate the failure surface using binary search:
   - For test failures: run in isolation, swap fixtures, bisect test order.
   - For build failures: comment out imports, check specific files.
   - For runtime failures: add boundary logging, check recent changes with `git log`.
   - For regressions: use `git bisect` to find the breaking commit.
3. **Hypothesize**: State the root cause theory explicitly: "X is happening because Y, and fixing Z should resolve it because..."
4. **Verify**: Confirm the hypothesis before applying the fix. The fix should work for the predicted reason, not by accident.

## Common root cause patterns

- Type mismatch (wrong shape passed to function or API)
- Missing or wrong dependency version
- Stale state (cached build, outdated lock file, stale generated code)
- Environment drift (works locally, fails in CI; version-specific behavior)
- Race condition (async operations completing in unexpected order)
- Import or path error (wrong relative path, case sensitivity, missing extension)

## Constraints

- Must preserve:
- Risky areas:
- Validation required:

## Deliverables

- root cause (specific mechanism, not just symptom description)
- smallest correct fix (do not refactor surrounding code)
- regression test that would have caught this failure
- rollback note (how to undo the fix if it causes new problems)
- updated WHERE_LEFT_OFF.md with fix details
