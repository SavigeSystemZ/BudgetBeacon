# Heretic Abliteration Plugin

This plugin provides downstream agents with a governed wrapper for host-local Heretic model abliteration workflows.

## Usage

Agents should invoke this plugin only when the user or repo-local plan explicitly authorizes a local model abliteration workflow and the justification has been recorded per `_system/HERETIC_ABLITERATION_PROTOCOL.md`.

### Command

From an installed repo root, run:

```bash
./_system/plugins/heretic-abliteration/decensor.sh <model_name_or_path>
```

For example:

```bash
./_system/plugins/heretic-abliteration/decensor.sh Qwen/Qwen3-4B-Instruct-2507
```

## Internal Dependencies

This script is a wrapper around a host-local Heretic installation and does not copy Heretic into the downstream repo. Resolution order:

1. `HERETIC_DIR=/path/to/heretic-master`
2. `~/.MyAppZ/_HERETIC_META_SYSTEM_ENHANCMENTS/heretic-master`
3. `~/.MyAppZ/_HERETIC_META_SYSTEM_ENHANCEMENTS/heretic-master`

The misspelled `ENHANCMENTS` path is intentionally supported because that is the current donor checkout name on the maintainer workstation.
