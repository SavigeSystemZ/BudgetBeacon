# Testing Patterns

## Use when

- the test suite needs structure beyond ad-hoc unit tests
- coverage is inconsistent or tests are brittle and slow
- the team needs guidance on test types, fixture management, or CI integration

## What to emulate

- test pyramid: many fast unit tests, fewer integration tests, minimal end-to-end tests
- unit tests that test behavior through public interfaces, not implementation details
- integration tests that verify real boundaries (database, API, file system) with controlled setup/teardown
- contract tests between services that catch interface drift before deployment
- fixture management: shared factories for test data, isolated per test, cleaned up after
- snapshot testing for serialized output (API responses, rendered components) with explicit update workflow
- test-driven bug fixes: reproduce the bug as a failing test before fixing
- CI integration: tests run on every push, flaky tests quarantined and tracked in `FIXME.md`

## What not to inherit

- tests coupled to implementation details (private methods, internal state)
- large integration test suites running where unit tests would suffice
- mocks for everything including the system under test
- tests that pass in isolation but fail when run together (shared mutable state)

## Adoption checklist

1. Document the test strategy in `TEST_STRATEGY.md` with coverage targets per layer.
2. Organize tests to mirror the source tree with clear unit/integration/e2e separation.
3. Add shared test factories for common data setup.
4. Run the full test suite in CI on every push.
5. Track flaky tests in `FIXME.md` with quarantine and investigation plan.
6. Add contract tests for all service-to-service boundaries.
7. Require a failing test before merging a bug fix.
