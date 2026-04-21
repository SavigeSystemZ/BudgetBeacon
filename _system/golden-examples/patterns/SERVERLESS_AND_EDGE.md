# Serverless and Edge Pattern

## Use when

- the application uses cloud functions, edge workers, or serverless runtimes
- cold start latency matters and must be mitigated
- the system must scale to zero and scale up on demand
- request routing happens at the edge before reaching origin servers

## What to emulate

- small, focused functions with a single responsibility and bounded execution time
- cold start mitigation through warm-up strategies, minimal dependencies, and lazy initialization
- stateless function design with external state in managed stores (KV, database, object storage)
- edge routing for latency-sensitive paths (auth, redirects, A/B testing, geolocation)
- structured error handling with automatic retry for transient failures and dead-letter for permanent failures
- infrastructure-as-code for all function and edge worker configuration
- local development parity using emulators or function frameworks
- cost-aware design with execution time budgets and memory allocation monitoring

## What not to inherit

- long-running functions that should be background workers or services
- tight coupling between functions that creates hidden synchronous call chains
- vendor lock-in without an abstraction layer for the most critical business logic
- large dependency bundles that inflate cold start times

## Adoption checklist

1. Set execution time and memory budgets per function in `PERFORMANCE_BUDGET.md`.
2. Document the function inventory and trigger types in `ARCHITECTURE_NOTES.md`.
3. Use infrastructure-as-code for all deployable function configuration.
4. Add cold start latency to the monitoring dashboard.
5. Implement local emulation for development and testing.
6. Add dead-letter handling for all async triggers.
7. Review dependency bundle sizes as part of the packaging gate.
