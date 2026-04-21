# Architectural Invariants

Record the rules that should almost never change.

## Typical entries

- runtime must not depend on `_system/`
- protected module boundaries
- non-negotiable data contracts
- install or launch invariants
- security or audit invariants

## Entries

- Invariant: runtime code and generated runtime scaffolds must not depend on `_system/`
  Why it matters: the agent operating system must remain a repo-local guidance layer, not a runtime dependency

- Invariant: repo-local runtime and product facts override generic host or tool assumptions
  Why it matters: host/orchestrator instructions may add task context but must not silently replace repo truth

- Invariant: canonical instruction contracts live in explicit repo files and may have machine-readable mirrors, but overlays are not allowed to become second sources of truth
  Why it matters: drift grows fastest when adapters and prompt packs restate long rule bodies

- Invariant: generated trust artifacts such as the system registry, operating profile, and integrity manifest must be reproducible from committed source surfaces
  Why it matters: maintainers and hosts need deterministic evidence, not hand-edited generated files

- Invariant: template neutrality takes precedence over making the source template superficially strict-green by hardcoding app-specific facts
  Why it matters: the template must remain reusable across many repos and host environments
