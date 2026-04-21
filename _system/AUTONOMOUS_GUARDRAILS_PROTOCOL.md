# Autonomous Guardrails Protocol

Use this protocol to run recurring integrity, validation, drift, and hallucination
risk checks automatically in installed repos.

## Goal

Provide continuous confidence checks without requiring manual operator runs for
every session.

## Components

- `bootstrap/run-autonomous-guardrails.sh`
  - executes recurring guardrail checks
  - records health history
  - writes timestamped logs under `_system/automation/`
  - optionally writes diagnostic and trend JSON artifacts
  - supports `--allow-warn` so recurring schedulers can keep running while
    still surfacing warnings in artifacts
- `bootstrap/install-autonomous-guardrails.sh`
  - installs recurring schedule as user `systemd` timer when possible
  - falls back to user `cron` when `systemd --user` is unavailable
  - supports `--dry-run` to print the exact unit files or crontab line without
    mutating systemd, crontab, or `~/.config/systemd/user` (use for CI and proofs)
  - when using the cron fallback, intervals above 59 minutes are approximated with
    an hourly cron pattern (for example, 120 minutes maps to every 2 hours)

## Recommended cadence

- `quick` mode every 30-120 minutes for active repos
- `full` mode every 6-24 hours
- strict mode for release-candidate windows

## Check scope

`full` mode delegates to `system-doctor.sh` (with report + record).

`quick` mode runs an operations-focused subset designed for frequent cadence:

- `validate-system.sh` (optionally strict)
- `verify-integrity.sh --check`
- `validate-instruction-layer.sh`
- `check-system-awareness.sh`
- `check-hallucination.sh`
- `check-network-bindings.sh`
- `check-repo-permissions.sh`

`validate-system.sh` includes `check-delivery-gate-alignment.sh` (contract and
delivery-gate discoverability). If alignment fails, see `_system/TROUBLESHOOTING.md`
(**Delivery-gate alignment check fails**).

Both modes append `_system/health-history.json` when present.

Full-mode checks can include:

- structural validation
- instruction-layer validation
- integrity verification
- system-awareness checks
- hallucination-risk checks
- working-file staleness and evidence-quality checks
- drift checks (when source template path is provided)

## Safety rules

- run as repo owner, never as root
- do not auto-commit from guardrail runs
- do not auto-heal without explicit operator approval
- treat warnings as action items, not silent noise

## Output artifacts

- `_system/automation/guardrails-<timestamp>.log`
- `_system/automation/diagnostic-<timestamp>.json` (full mode)
- `_system/automation/trend-<timestamp>.json` (full mode)
- `_system/automation/latest.log` symlink

`_system/automation/*.log` and `*.json` are runtime artifacts and are excluded
from registry-managed contract checks; `README.md` remains managed.

## Installation examples

```bash
# Preview scheduler payload without installing (systemd or cron, host-dependent)
bash bootstrap/install-autonomous-guardrails.sh . --dry-run --mode quick --interval 120

# Full checks every 2 hours (default)
bash bootstrap/install-autonomous-guardrails.sh . --mode full --interval 120

# Fast checks every 30 minutes
bash bootstrap/install-autonomous-guardrails.sh . --mode quick --interval 30

# With drift source and strict mode
bash bootstrap/install-autonomous-guardrails.sh . \
  --source /path/to/_AI_AGENT_SYSTEM_TEMPLATE/TEMPLATE \
  --mode full \
  --interval 180 \
  --strict
```

## Operator workflow

1. install recurring scheduler in each active app repo
2. monitor `_system/automation/latest.log`
3. treat repeated warnings/failures as stop-and-repair signals
4. run manual `bootstrap/system-doctor.sh . --strict --report` before release claims
