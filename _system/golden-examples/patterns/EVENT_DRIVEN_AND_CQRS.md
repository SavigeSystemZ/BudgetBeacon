# Event-Driven and CQRS Pattern

## Use when

- the system benefits from separating read and write models
- events are the primary mechanism for state propagation between components
- eventual consistency is acceptable and simplifies the architecture
- audit trails or event replay capabilities are needed

## What to emulate

- commands as validated intent (write side) and queries as optimized projections (read side)
- events as immutable facts with schema versioning and backward compatibility
- event stores or message buses with at-least-once delivery and idempotent handlers
- projections that rebuild from the event stream for read-side optimization
- dead-letter queues for poison messages with alerting and manual retry
- clear separation between command handlers, event publishers, and projection builders
- compensating actions or saga orchestration for multi-aggregate consistency

## What not to inherit

- CQRS for simple CRUD domains where a single model suffices
- event sourcing without a clear audit or replay requirement
- unbounded event streams without retention policies or compaction
- synchronous event processing disguised as async (blocking on event completion)

## Adoption checklist

1. Document the event schema in `ARCHITECTURE_NOTES.md` with versioning rules.
2. Define command and query boundaries in the service layer.
3. Implement idempotent event handlers with deduplication keys.
4. Add dead-letter queue monitoring and alerting.
5. Record retention and compaction policies in `DESIGN_NOTES.md`.
6. Add integration tests that verify projection consistency after event replay.
7. Document compensating actions for each saga in the system.
