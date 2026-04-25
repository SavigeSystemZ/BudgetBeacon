# Session Environment Report Contract

This contract defines a portable `/environment` style report for startup safety and operator visibility.

## Required report fields

- repo root path
- repo basename
- whether repo is under `~/.MyAppZ`
- whether repo is `_AI_AGENT_SYSTEM_TEMPLATE`
- resolved authority mode (template-maintainer, downstream-project, out-of-bound)
- active branch and remote summary
- orphan snapshot branch presence
- adapter surfaces detected
- key contract files present/missing
- workspace/scope mismatch findings
- redirect shim status findings

## Output formats

- Human-readable summary (default)
- JSON (`--json`) for tooling

## Producers

- `bootstrap/emit-session-environment.sh`
- Cursor command surface `/.cursor/commands/environment.md`

## Startup usage

Recommended pre-write flow:

1. load context
2. run working-directory and target consistency checks
3. emit environment report
4. continue only if no blocking mismatches
