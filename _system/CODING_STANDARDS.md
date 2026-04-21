# Coding Standards

These standards apply to all runtime code produced or modified by any agent in this repo.

## Naming

- Use descriptive, intention-revealing names. Avoid abbreviations except universally understood ones (id, url, http, api).
- Functions: verb-first (`getUserById`, `validate_input`, `parse_response`).
- Booleans: question-form (`isVisible`, `has_permission`, `can_edit`).
- Constants: `UPPER_SNAKE_CASE`.
- Types and classes: `PascalCase`.
- Files: match the language convention. Kebab-case for web assets, snake_case for Python, PascalCase for component files if that is the project norm.
- Avoid generic names like `data`, `info`, `temp`, `result`, `item`, `stuff`, `handler` unless the scope is genuinely trivial.

## Functions and modules

- Each function does one thing. If you need "and" to describe it, split it.
- Keep functions short enough to read in one screen. If a function exceeds 40 lines, look for extraction opportunities.
- Limit parameters to 3-4. Use an options object or config struct beyond that.
- Avoid boolean flag parameters that secretly branch behavior. Prefer two clearly named functions or an enum.
- Pure functions over side-effectful ones where practical.
- Collocate related logic. A helper used by one function should live near that function, not in a global utils file.
- Avoid premature abstraction. Three concrete implementations is the threshold for considering a shared abstraction.

## Error handling

- Handle errors at the boundary where you can do something useful. Do not catch and swallow silently.
- Use typed or structured errors. Prefer `new AppError('NOT_FOUND', { id })` over `throw new Error('not found')`.
- Distinguish expected failures (user input, network, external services) from programming bugs.
- Never use exceptions for control flow.
- Always clean up resources (connections, file handles, timers) in finally blocks or RAII patterns.
- Log errors with enough context to reproduce: what was attempted, with what inputs, and what failed.
- Return meaningful error responses to callers. Never expose raw stack traces, internal paths, or database details to end users.

## Resource efficiency

- Close connections, file handles, streams, and subscriptions when done.
- Cancel pending async work on component unmount or scope exit.
- Avoid unbounded in-memory collections. Stream or paginate large data sets.
- Use lazy initialization for expensive resources that may not be needed.
- Prefer database-level filtering and aggregation over fetching everything and filtering in application code.
- Avoid N+1 query patterns. Batch related lookups.
- Cache expensive computations with clear invalidation rules. Never cache without a plan for staleness.
- Profile before optimizing. Measure, don't guess.

## Type safety

- Use the strongest type system available in the project stack.
- Prefer strict mode (`strict: true` in TypeScript, `mypy --strict` in Python, etc.).
- Avoid `any`, `object`, `unknown` casts, and type assertions unless genuinely necessary with a comment explaining why.
- Define explicit types for API boundaries, config shapes, and shared data structures.
- Use discriminated unions and exhaustive checks instead of stringly-typed conditionals.

## Data handling

- Validate external data at the boundary (user input, API responses, file reads, environment variables).
- Use schema validation (zod, pydantic, joi, etc.) for complex shapes.
- Sanitize user-supplied strings before rendering in HTML, SQL, shell commands, or log output.
- Prefer immutable data structures for shared state. Mutate only within well-defined scopes.
- Never trust client-side validation alone. Always revalidate on the server.

## Async and concurrency

- Use structured concurrency. Every spawned task must be awaited, joined, or explicitly fire-and-forget with justification.
- Handle cancellation and timeout for every external call.
- Avoid shared mutable state between concurrent tasks. Use message passing, queues, or synchronized access patterns.
- Set sensible timeouts on all network requests. Never wait indefinitely.
- Use backoff and jitter for retries. Never retry in a tight loop.

## Testing expectations

- New behavior needs tests. Modified behavior needs updated tests.
- Test the contract (inputs and outputs), not the implementation details.
- Keep tests deterministic. Mock time, randomness, and external services.
- Name tests to describe the scenario and expected outcome, not the function name.
- Prefer fast, isolated unit tests. Use integration tests for boundary verification.
- One assertion per test concept. Multiple assertions are fine if they verify one logical outcome.

## Anti-patterns to avoid

- God objects or god functions that do everything.
- Deeply nested callbacks or promise chains. Flatten with async/await or composable pipelines.
- Magic numbers and magic strings. Use named constants.
- Copy-paste code across more than two locations without extraction.
- Commented-out code left in the codebase. Delete it; version control remembers.
- Console.log / print debugging left in production code.
- Overuse of inheritance. Prefer composition.
- Barrel files that re-export everything and defeat tree-shaking.
- Circular dependencies between modules.
- Catching generic exceptions at the top level without specific error handling.
