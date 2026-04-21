# API Design Standards

APIs are contracts. A well-designed API is easy to use correctly and hard to use incorrectly.

## General principles

- Design for the consumer, not the implementation.
- Be consistent. If one endpoint uses `created_at`, every endpoint uses `created_at`.
- Be predictable. Similar resources should behave similarly.
- Be explicit. Never require the caller to guess structure, behavior, or error semantics.
- Version from day one. Breaking changes go in a new version.

## REST conventions

### URLs

- Use nouns for resources: `/users`, `/orders`, `/invoices`.
- Use plural nouns for collections: `/users` not `/user`.
- Nest for clear ownership: `/users/{id}/orders`.
- Limit nesting to two levels. Beyond that, use top-level resources with filters.
- Use kebab-case for multi-word paths: `/order-items`, not `/orderItems`.
- No verbs in URLs. Use HTTP methods for actions: `POST /orders` not `POST /create-order`.
- Use query parameters for filtering, sorting, and pagination: `/users?role=admin&sort=-created_at&page=2`.

### HTTP methods

- `GET`: read. Safe, idempotent, cacheable. Never mutate state.
- `POST`: create or trigger an action. Not idempotent.
- `PUT`: full replace of a resource. Idempotent.
- `PATCH`: partial update. Send only changed fields.
- `DELETE`: remove. Idempotent. Return 204 on success.

### Status codes

- `200`: success with body.
- `201`: created. Include `Location` header pointing to the new resource.
- `204`: success with no body (DELETE, PATCH with no return).
- `400`: client sent an invalid request. Include field-level error details.
- `401`: not authenticated. The request lacks valid credentials.
- `403`: authenticated but not authorized for this action.
- `404`: resource not found.
- `409`: conflict (duplicate, version mismatch).
- `422`: valid syntax but semantically invalid (business rule violation).
- `429`: rate limited. Include `Retry-After` header.
- `500`: server error. Log the details. Return a safe error to the client.

## Error responses

Use a consistent error envelope:

```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "The request contains invalid fields.",
    "details": [
      { "field": "email", "issue": "must be a valid email address" },
      { "field": "age", "issue": "must be a positive integer" }
    ],
    "request_id": "req_abc123"
  }
}
```

- Always include a machine-readable error code.
- Always include a human-readable message.
- Include field-level details for validation errors.
- Include a request ID for tracing.
- Never expose stack traces, SQL queries, or internal paths in error responses.

## Pagination

- Use cursor-based pagination for large or frequently updated collections.
- Use offset-based pagination only for small, stable collections.
- Return pagination metadata in the response body:

```json
{
  "data": [...],
  "pagination": {
    "next_cursor": "eyJpZCI6MTAwfQ==",
    "has_more": true,
    "total_count": 1432
  }
}
```

- Default page size: 20-50. Maximum: 100. Reject requests for more.
- Never return unbounded collections.

## Filtering, sorting, and field selection

- Filter via query parameters: `?status=active&created_after=2024-01-01`.
- Sort via `sort` parameter with `-` prefix for descending: `?sort=-created_at,name`.
- Allow field selection via `fields` parameter: `?fields=id,name,email`.
- Validate filter and sort parameters. Return 400 for unknown fields.

## Versioning

- Version in the URL path: `/v1/users`, `/v2/users`.
- Never break existing version contracts. Additive changes (new fields, new endpoints) are fine.
- Deprecate old versions with advance notice and a migration guide.
- Document the sunset timeline for deprecated versions.

## Authentication and authorization

- Use standard authentication: OAuth 2.0, JWT, or API keys depending on context.
- Pass tokens in the `Authorization` header, not in query parameters or cookies (for APIs).
- Validate and verify tokens on every request. Never trust unverified tokens.
- Implement role-based or scope-based access control at the endpoint level.
- Return 401 for missing or invalid credentials. Return 403 for insufficient permissions.
- Log authentication failures with enough context for security monitoring.

## Rate limiting

- Apply rate limits to all public and authenticated endpoints.
- Return `429 Too Many Requests` with a `Retry-After` header.
- Include rate limit headers in all responses: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.
- Use sliding window or token bucket algorithms. Avoid fixed window where burstiness matters.

## Request and response conventions

- Use `application/json` as the default content type.
- Use consistent date format: ISO 8601 (`2024-01-15T09:30:00Z`).
- Use consistent ID format across the API (UUID, nanoid, or integer — pick one).
- Use snake_case for JSON field names in most APIs. Match the project convention.
- Wrap collection responses: `{ "data": [...] }` not bare arrays.
- Include `created_at` and `updated_at` timestamps on all persisted resources.
- Support `ETag` and `If-None-Match` for caching where beneficial.

## Documentation

- Document every endpoint with method, URL, parameters, request body, response shape, and error cases.
- Provide runnable examples.
- Use OpenAPI / Swagger for REST APIs. Generate from code where possible.
- Keep documentation in sync with the implementation. Stale docs are worse than no docs.

## Security

- Validate all input at the API boundary. Never trust client-supplied data.
- Sanitize data before database queries (parameterized queries, never string interpolation).
- Implement CORS with explicit allowed origins. Never use `*` in production.
- Use HTTPS everywhere. Reject plain HTTP.
- Set security headers: `Strict-Transport-Security`, `X-Content-Type-Options`, `X-Frame-Options`.
- Do not leak internal information through verbose error messages, headers, or response timing.
