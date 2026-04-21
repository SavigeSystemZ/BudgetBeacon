# GraphQL API Blueprint

Use this when the product needs a GraphQL schema with explicit resolver boundaries.

## Expectations

- Schema-first or generated contract committed to the repo
- Resolver logic separated from transport setup
- N+1 mitigation plan from the first milestone
- Auth and field-level access rules documented early

## Validation commands

- Schema validation or generation check
- Resolver unit tests
- API integration tests against representative queries and mutations

## First milestone suggestion

1. Publish the first schema and resolver map.
2. Add query and mutation smoke tests.
3. Record auth, pagination, and error-shape decisions in architecture notes.
