# Validation Command Discovery Protocol

`bootstrap/discover-validation-commands.sh` discovers available validation
commands from package manifests and repo scripts. Missing commands are reported
as gaps (`missing` or `not_applicable`), never fabricated.

`bootstrap/run-validation-autopilot.sh` executes discovered commands in
deterministic order and produces JSON evidence.
