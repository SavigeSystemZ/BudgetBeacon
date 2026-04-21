# Agent Performance Guide

How to choose the right agent/model for each task based on measured capabilities.

## Model capability dimensions

1. **Context window** — how much the model can ingest at once
2. **Generation quality** — accuracy and completeness of output by language
3. **Planning** — multi-step reasoning and architecture design
4. **Review** — code review, bug detection, security analysis
5. **Speed** — tokens per second for interactive use
6. **Cost** — per-token pricing tier (low/medium/high)

## Task-to-model mapping

| Task type | Primary dimension | Recommended tier |
|-----------|------------------|-----------------|
| Whole-repo analysis | Context + planning | Tier S models (1M+) |
| Greenfield architecture | Planning + context | Tier S or A |
| Feature implementation | Generation quality | Tier A or B |
| Bug fix / debug | Review + planning | Tier A or B |
| Code review | Review | Tier A or B |
| Quick edits / formatting | Speed | Tier C or D (smaller models) |
| Documentation | Generation quality | Tier B or C |
| Test generation | Generation quality | Tier B |
| Refactoring | Planning + review | Tier S or A |
| Security audit | Review | Tier S or A |
| CI automation | Speed + cost | Tier C or D |

## Model family profiles

See `agent-performance-profiles.json` for machine-readable capability ratings.

### Tier S: Infinite context (1M+)

- **Gemini 2.5 Pro / Flash** — Extreme context window (1M+). Best for whole-repo analysis, cross-cutting architectural refactors, and deep codebase investigations.

### Tier A: Full context (200K+)

- **Claude Opus/Sonnet 4** — Strongest planning and review. Best for architecture, complex debugging, security audits.
- **GPT-4o / o3** — Strong generation quality across all languages. Good planning.
- **DeepSeek R1** — Strong reasoning for complex logic and debugging.
- **Llama 3.3 70B** — Large, high-quality open-source model.

### Tier B: Standard context (32K–128K)

- **Claude Haiku 4** — Fast, cost-effective. Good for feature implementation and docs.
- **GPT-4o-mini** — Budget-friendly with solid quality. Good for tests and docs.
- **DeepSeek V3** — Strong code generation, especially Python and systems languages.
- **Mistral Large** — Solid general-purpose model with a standard context window.

### Tier C: Compact context (8K–32K)

- **Codestral / Mistral Large** — Good local/hosted option for code completion.
- **Qwen 2.5 Coder** — Strong code generation for its size class.

### Tier D: Minimal context (4K–8K)

- **CodeLlama 7B/13B** — Local-only. Best for simple edits and completions.
- **Phi-3/4** — Small but capable for quick tasks.
- **StarCoder2** — Specialized for code completion.

## Multi-agent delegation

When using multiple agents in the same repo:

1. **Assign by strength**: Use Tier A for planning and review, Tier B/C for implementation.
2. **Context budget**: Use `bootstrap/emit-tiered-context.sh --model <name>` to get the right load for each model.
3. **Single active writer**: Only one agent writes at a time (see `MULTI_AGENT_COORDINATION.md`).
4. **Handoff quality**: Tier A models produce better handoff packets. Use them for `WHERE_LEFT_OFF.md` updates.

## Measuring effectiveness

Track prompt pack success/failure rates per model using the protocol in `PROMPT_EFFECTIVENESS_TRACKING.md`. Over time, this builds evidence for which models work best for which task types in your specific repo.

## Updating profiles

Model capabilities change with new releases. Update `agent-performance-profiles.json` when:
- A new model family is released
- A model's context window changes significantly
- Measured generation quality changes after a version update
- Cost tiers shift

The profiles ship as static JSON. Override individual ratings based on your team's experience.
