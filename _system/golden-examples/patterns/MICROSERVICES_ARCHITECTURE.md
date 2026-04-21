# Microservices Architecture Pattern

## Use when

- the application is decomposed into independently deployable services
- service boundaries, API gateways, or inter-service communication need design
- the repo contains multiple service roots or a monorepo with shared libraries

## What to emulate

- clear service boundaries aligned with business capabilities, not technical layers
- explicit API contracts between services (OpenAPI, protobuf, GraphQL schema)
- circuit breaker and retry patterns for inter-service calls with backoff
- saga or choreography patterns for distributed transactions instead of 2PC
- service discovery and health-check endpoints for each service
- shared libraries extracted only when two or more services genuinely need the same logic
- independent deployment pipelines per service with contract testing gates
- structured logging with correlation IDs that propagate across service boundaries

## What not to inherit

- premature decomposition of a monolith before domain boundaries are proven
- shared databases between services that couple their schemas
- synchronous call chains deeper than two hops without async decoupling
- service meshes or infrastructure complexity before the team size justifies it

## Adoption checklist

1. Define service boundaries in `ARCHITECTURE_NOTES.md` with a dependency diagram.
2. Document API contracts in a shared schema directory or per-service spec.
3. Implement health and readiness endpoints per service.
4. Add circuit breaker configuration for all outbound service calls.
5. Use correlation IDs in structured logs across all services.
6. Add contract tests that run in CI before deployment.
7. Keep shared code in an explicit library with its own version and test suite.
