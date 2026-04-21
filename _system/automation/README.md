# Automation Artifacts

This directory stores recurring guardrail run artifacts in installed repos.

Expected files (created at runtime by `bootstrap/run-autonomous-guardrails.sh`):

- `guardrails-<timestamp>.log`
- `diagnostic-<timestamp>.json` (full mode)
- `trend-<timestamp>.json` (full mode)
- `latest.log` symlink (points to latest run log)

In the source template, this directory contains this README plus
`.gitignore` rules so runtime logs and JSON are not committed accidentally.
