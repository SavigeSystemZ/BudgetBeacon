# AI Runtime Foundation

This directory is project-owned runtime scaffolding for pluggable AI providers and chatbot behavior.

## Included

- `llm_config.yaml` provider and model configuration example
- `chatbot-intents.md` starter intents and action mapping guidance

## Contract

- Keep provider credentials in environment variables or secret stores.
- Keep runtime application code independent from `_system/`.
- Route privileged or state-changing actions through an explicit permission and audit layer.
