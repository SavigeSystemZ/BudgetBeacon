# Concise session (token-efficient output)

Opt-in **short assistant replies** to reduce **output** tokens (same idea as the community Caveman pattern; see `.cursor/skills/concise-communication/SKILL.md`).

## Steps

1. Ask the user for **intensity** if not given: `lite` | `full` (default) | `ultra`.
2. Load and follow `.cursor/skills/concise-communication/SKILL.md`.
3. Remain in concise mode until the user says **normal mode** or **stop concise**.

## Notes

- Does **not** relax `AGENTS.md`, `PROJECT_RULES.md`, validation gates, or handoff quality.
- For **input** token savings, prefer tiered loading (`bootstrap/emit-tiered-context.sh`, `_system/CONTEXT_BUDGET_STRATEGY.md`). For optional compression of long human notes (eligible paths only), see `/compress-context` and `bootstrap/compress-context-file.sh`.
