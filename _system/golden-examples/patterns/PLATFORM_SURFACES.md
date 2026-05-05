# Platform Surfaces Pattern

## Use when

- deciding how to separate runtime roots across web, desktop, mobile, packaging, ops, and AI
- expanding a repo into more than one delivery surface
- avoiding boundary drift between runtime code and the agent operating system

## Primary donors

- curated-donor

## What to emulate

- explicit runtime roots and packaging roots
- clear separation between web, desktop, mobile, install, and AI scaffolds
- runtime/system boundary enforcement
- platform growth that stays understandable to future agents

## What not to inherit

- unnecessary surfaces created before the product needs them
- mixing `_system/` content into runtime dependencies
- carrying donor brand, tone, or product taxonomy into another repo

## Adoption checklist

1. Add new surfaces only when the repo truly needs them.
2. Keep ownership of each root explicit in `_system/PROJECT_PROFILE.md`.
3. Validate each delivery surface with the narrowest real command available.
4. Keep packaging/install guidance repo-local after install.
