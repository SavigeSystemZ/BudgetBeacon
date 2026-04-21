# Real-Time Collaboration Pattern

## Use when

- the application requires live updates between multiple users or systems
- WebSocket, SSE, or long-polling connections are part of the architecture
- conflict resolution for concurrent edits is needed
- presence tracking or live cursors are user-facing features

## What to emulate

- WebSocket or SSE connections with automatic reconnection and exponential backoff
- optimistic updates on the client with server reconciliation on conflict
- operational transform or CRDT-based conflict resolution for concurrent document editing
- presence tracking with heartbeat intervals and graceful timeout handling
- connection state management (connecting, connected, reconnecting, disconnected) exposed to the UI
- message ordering guarantees appropriate to the domain (total order, causal, or best-effort)
- fan-out architecture that decouples message production from delivery
- graceful degradation to polling when persistent connections are unavailable

## What not to inherit

- WebSocket for data that changes infrequently (use standard HTTP caching instead)
- unbounded connection pools without backpressure or connection limits
- client-side conflict resolution without server validation
- real-time features without offline fallback or reconnection strategy

## Adoption checklist

1. Document the connection protocol and message format in `ARCHITECTURE_NOTES.md`.
2. Implement reconnection with exponential backoff and jitter.
3. Add connection state to the UI with user-visible indicators.
4. Define conflict resolution strategy per data type in `DESIGN_NOTES.md`.
5. Set connection limits and implement backpressure.
6. Add integration tests for reconnection, conflict resolution, and fan-out.
7. Monitor connection counts, message latency, and reconnection rates.
