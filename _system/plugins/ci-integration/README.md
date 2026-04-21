# CI Integration Plugin

Generates and validates CI configuration based on the project profile.

## Hooks

- `ci.pre_commit` — validates that CI config matches declared validation commands
- `ci.post_test` — records test results for trend tracking

## What it does

1. Reads `_system/PROJECT_PROFILE.md` for declared validation commands.
2. Checks existing CI config (`.github/workflows/`, `.gitlab-ci.yml`) for alignment.
3. Reports mismatches between declared commands and CI pipeline steps.
4. After tests, records pass/fail status for trend tracking.

## Configuration

No additional configuration needed. Auto-detects CI platform from repo structure.
