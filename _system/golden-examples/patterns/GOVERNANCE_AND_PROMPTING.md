# Governance And Prompting Pattern

## Use when

- adding or refactoring prompt packs
- tightening repo rules or instruction precedence
- reducing duplicated adapter wording

## Primary donors

- IdeaForge
- EtherWeave

## What to emulate

- layered contracts instead of one giant prompt wall
- explicit precedence, fallback, and provenance rules
- least-privilege MCP posture
- prompt packs that are scoped, copy-ready, and grounded in canonical docs

## What not to inherit

- vendor lock-in phrasing
- duplicated rules spread across every adapter
- app-specific product language baked into generic governance docs

## Adoption checklist

1. Put the shared rule in one canonical file first.
2. Let adapters reference the canonical rule instead of rewriting it.
3. Make prompt packs task-shaped and validation-aware.
4. Keep MCP guidance additive and optional, never mandatory for normal progress.
5. Update indices and discovery docs in the same pass.
