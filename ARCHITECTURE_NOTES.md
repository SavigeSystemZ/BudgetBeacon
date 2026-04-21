# Architecture Notes

Use this file for durable architecture direction, not one-off implementation chatter.

## Current shape

- system boundaries:
- major modules:
- highest-value seams:
- primary data flows:

## Boundary rules

- protected boundaries:
- modules that may change together:
- modules that should stay independent:

## Interface contracts

- internal contracts that must remain stable:
- external contracts that need migration discipline:

## Change pressure points

- likely refactor zones:
- fragile coupling to watch:
- scaling or reliability pressure points:

## Migration watchpoints

- migrations likely to be needed later:
- compatibility concerns:
- rollback concerns:

## Review prompts

- Does the proposed change improve or worsen separation of concerns?
- Does it create hidden coupling?
- Does it preserve a clear runtime-vs-system boundary?
