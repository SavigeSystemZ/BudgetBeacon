# Chatbot Guide

Use the generated `ai/` directory as the runtime-owned entrypoint for pluggable LLM providers and app-specific chatbot actions.

## Runtime surfaces

- `ai/llm_config.yaml`
- `ai/chatbot-intents.md`

## Contract

- Keep provider credentials in env vars or a secret manager.
- Treat `_system/llm_config.yaml.example` as the schema reference only.
- Resolve documentation questions from local markdown first.
- Route state-changing actions through an explicit permission hook and audit logger.

## Supported interaction modes

- CLI REPL
- REST endpoint
- GUI side panel when the app has a UI shell

## Extension model

- Add project-owned intents.
- Map intents to command-bus or function calls in runtime code.
- Log actor, action, target, and outcome for privileged operations.
