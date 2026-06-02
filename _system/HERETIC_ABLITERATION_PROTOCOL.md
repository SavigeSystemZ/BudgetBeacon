# HERETIC ABLITERATION PROTOCOL

## Overview
This protocol defines when and how agents in the AI Agent System Template (AIAST) may use the Heretic system for host-local model abliteration workflows. It keeps the capability explicit, auditable, and independent from runtime application code.

## Applicability
This protocol applies only when a user or repo-local plan explicitly authorizes work on a local model's refusal/alignment behavior. It is not a default inference path for normal app-building tasks.

## Governance Rules
1. **Explicit Justification:** Agents must not alter model refusal behavior opportunistically. Log the user authorization, model identifier, intended use, and rollback point in `WHERE_LEFT_OFF.md` or `PLAN.md` before running the wrapper.
2. **Tool Usage:** Agents must use the official wrapper script located at `_system/plugins/heretic-abliteration/decensor.sh` or the plugin runner `_system/plugins/heretic-abliteration/run.sh`.
3. **Host-Local Dependency:** Heretic itself remains outside the installable template. The wrapper resolves `HERETIC_DIR` first, then the known maintainer donor paths under `~/.MyAppZ/`.
4. **Artifact Retention:** Logs, model checkpoints, adapter outputs, and configuration adjustments created during the abliteration process must stay in the project's designated runtime directory or model cache, not inside `_system/`.
5. **Runtime Boundary:** Application runtime code must not depend on `_system/` or on the host-local Heretic checkout.
6. **Validation:** After the run, record the exact command, output location, active model configuration change, and whether rollback was verified.

## Execution Pattern
When a local model abliteration workflow is authorized:

1. Ensure the model is available locally or downloaded via Hugging Face.
2. Confirm `uv` is installed and the wrapper can resolve the Heretic checkout.
3. Run the wrapper script: `./_system/plugins/heretic-abliteration/decensor.sh <model_name_or_path>`.
4. Monitor the batch size optimization and output evaluation metrics.
5. Update only the relevant local model configuration, then record the before/after paths and validation evidence.
