# Security Scan Plugin

Runs secret detection and optional SAST tools as a unified security scan.

## Hooks

- `security.scan` — runs the full security scan suite
- `ci.pre_commit` — runs quick secret detection before commit

## What it does

1. Delegates to `bootstrap/scan-security.sh` for secret detection.
2. If `semgrep` is available, runs SAST rules against the source tree.
3. If `bandit` is available (Python repos), runs Python security linting.
4. Produces a unified JSON report at `_system/plugins/security-scan/last-report.json`.

## Configuration

No additional configuration needed. The plugin auto-detects available tools.
