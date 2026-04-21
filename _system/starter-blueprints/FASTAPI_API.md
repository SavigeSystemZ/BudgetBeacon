# FastAPI API Blueprint

Use this for Python API services that need clean contracts, testable routes, and explicit validation.

## Expected repo shape

```
app/
  main.py           application entrypoint
  routes/            route groups by domain
  models/            Pydantic request/response models (or schemas/)
  services/          business logic layer
  db/                database models and connection (if applicable)
  middleware/        custom middleware
tests/
  test_routes/       route-level integration tests
  test_services/     unit tests for business logic
pyproject.toml       project metadata and dependencies
uv.lock              lock file (or requirements.txt)
```

## Baseline stack

- FastAPI
- Python 3.11+
- Pydantic v2 for request/response models
- pytest for testing
- uvicorn for development server

## Validation commands

- Unit tests: `PYTHONPATH=. pytest -q`
- Build check: `python3 -m compileall app`
- Lint: `ruff check .` (if configured)
- Format: `ruff format .` (if configured)
- Typecheck: `mypy app/` (if configured)
- Dev server: `uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload`

## Quality expectations

- Explicit 4xx and 5xx behavior — every error has a typed response model, not raw exceptions.
- Typed request and response models (Pydantic) for every route. No raw dicts in or out.
- In AIAST scaffolded repos, use a `src/` layout or explicit package settings in
  `pyproject.toml`. Do not rely on flat setuptools auto-discovery while
  top-level foundation directories like `ops/`, `mobile/`, `packaging/`, or
  `ai/` are present.
- Proper HTTP status codes: 201 for creates, 204 for deletes, 422 for validation errors.
- Route tests for every public endpoint covering happy path, validation errors, and not-found.
- Structured logging — no `print()` in production code.
- Environment-based configuration — no hardcoded URLs, keys, or ports.
- Avoid hidden global state — use dependency injection for database connections and services.
- API versioning strategy decided early (path prefix `/v1/` or header-based).
- Commit backend ownership and exposure notes in `docs/security/backend-inventory.md` and `docs/security/architecture.md` before expanding the API surface.

## First milestone suggestion

1. Ship `/health` endpoint returning `{"status": "ok"}` and one real resource route with CRUD.
2. Confirm `PYTHONPATH=. pytest -q` passes with route tests covering happy path and error cases.
3. Confirm `python3 -m compileall app` passes with zero errors.
4. Confirm dev server starts and responds to `curl http://127.0.0.1:8000/health`.
5. Record API contract assumptions, versioning strategy, bind/port policy, and backend ownership in `ARCHITECTURE_NOTES.md` and `docs/security/backend-inventory.md`.
