# Memory Rules

Durable memory is for stable facts, decisions, preferences, and constraints that should survive tool changes.

## Good memory candidates

- app identity and purpose
- stable architecture boundaries
- durable product decisions
- preferred workflows and conventions
- persistent operator constraints

## Bad memory candidates

- raw secrets or credentials
- ephemeral logs
- temporary failures that belong only in a single session note
- noisy intermediate reasoning

## Rules

- repo files remain the primary source of truth
- do not store secrets
- when durable decisions change, update both memory and canonical docs
- record only stable facts that help future agents work correctly
