# Background Worker Blueprint

Use this for queue consumers, scheduled jobs, or long-running background processing.

## Expected repo shape

```
workers/
  main.py|main.ts|main.rs
  jobs/
  services/
tests/
ops/
```

## Baseline expectations

- Explicit job boundaries and retry behavior
- Idempotent handlers where retries are possible
- Structured logs with job or correlation IDs
- Health or readiness signal for worker supervision

## Validation commands

- Unit tests for job logic
- Integration tests for queue or broker interaction
- Service smoke test or supervised launch verification

## First milestone suggestion

1. Ship one real worker path with structured logs.
2. Define retry, dead-letter, and shutdown behavior.
3. Add supervisor or systemd unit verification.
