# Validation Command Discovery Protocol

`bootstrap/discover-validation-commands.sh` discovers available validation
commands from package manifests and repo scripts. Missing commands are reported
as gaps (`missing` or `not_applicable`), never fabricated.

`bootstrap/run-validation-autopilot.sh` executes discovered commands in
deterministic order and produces JSON evidence.

Discovery must distinguish:

- `found`: command exists and can be run by the current repo.
- `missing`: expected command is absent and should be tracked as a gap.
- `not_applicable`: command does not apply to the current archetype/profile.

Autopilot must not fabricate tool commands or skip a failing required gate
without recording the failure in validation evidence.
