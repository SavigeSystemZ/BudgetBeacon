---
name: prompt-pack-generator
description: Generate milestone prompt packs grounded in the repo's canonical docs.
---

# Prompt Pack Generator

## Inputs

- canonical docs
- milestone or phase goals
- required deliverables

## Steps

1. Reference the canonical docs by file name.
2. Add the host-safe startup preamble from `_system/PROMPT_EMISSION_CONTRACT.md`.
3. Write prompts for planning, implementation, validation, and handoff.
4. Require minimal diffs, no secrets, and explicit validation.
5. Keep prompts copy-paste ready without duplicating long repo rule bodies.
