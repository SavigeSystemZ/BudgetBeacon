# Error Handling Patterns

## Use when

- error handling is inconsistent across the codebase
- user-facing error messages are unclear or leak internal details
- retry logic, circuit breakers, or graceful degradation need structure

## What to emulate

- error taxonomy: distinguish operational errors (recoverable) from programmer errors (bugs)
- boundary error handling: validate and transform errors at system boundaries (API, database, external services)
- structured error responses with machine-readable codes, human-readable messages, and correlation IDs
- retry with exponential backoff and jitter for transient failures; fail fast for permanent errors
- circuit breaker pattern: open after N failures, half-open to probe, close on success
- graceful degradation: serve cached or default data when a dependency is unavailable
- user-facing messages that describe what happened and what the user can do, never raw stack traces
- centralized error logging with severity levels, context, and correlation to request traces

## What not to inherit

- catch-all exception handlers that swallow errors silently
- error messages that expose database schemas, file paths, or internal service names
- retry loops without backoff, jitter, or maximum attempt limits
- boolean success/failure returns that discard error context

## Adoption checklist

1. Define the error taxonomy in `CODING_STANDARDS.md` or `DESIGN_NOTES.md`.
2. Implement structured error responses at all API boundaries.
3. Add retry with backoff for all external service calls.
4. Map internal errors to user-facing messages at the presentation boundary.
5. Log errors with structured context including correlation IDs.
6. Add tests for error paths, not just happy paths.
7. Review error responses as part of the security review (no internal leakage).
