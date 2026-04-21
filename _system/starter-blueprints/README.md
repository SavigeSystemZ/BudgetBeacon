# Starter Blueprints

Use these blueprints when a new repo needs a strong first-pass shape instead of ad hoc bootstrapping.

## Available blueprints

- `REACT_VITE_TYPESCRIPT.md` - modern frontend app with strong visual and build defaults
- `FASTAPI_API.md` - Python API service with validation and test expectations
- `STATIC_FRONTEND.md` - no-framework frontend with clean structure and smoke verification
- `NEXT_JS_FULLSTACK.md` - Next.js App Router fullstack with TypeScript and Tailwind
- `PYTHON_CLI_TOOL.md` - Python CLI tool with structured commands and rich output
- `RUST_CLI_TOOL.md` - Rust CLI with release-binary discipline
- `GO_SERVICE.md` - Go service or daemon with simple deployment defaults
- `GRAPHQL_API.md` - schema-driven API with resolver boundaries
- `GRPC_SERVICE.md` - protobuf-backed service contract
- `BACKGROUND_WORKER.md` - queue worker or scheduler pattern
- `DATABASE_MIGRATIONS.md` - migration discipline across common ecosystems
- `TAURI_DESKTOP.md` - desktop app path for Linux-first packaging
- `FLUTTER_ANDROID_CLIENT.md` - Flutter-based Android client path with release-flavor discipline
- `UNIVERSAL_APP_PLATFORM.md` - multi-surface product architecture spanning web, API, worker, AI, packaging, and mobile

## Rules

- Treat these as launch patterns, not immutable rules.
- Adapt them to the actual product and constraints in `_system/PROJECT_PROFILE.md`.
- Use `bootstrap/recommend-starter-blueprint.sh <target-repo> --write` to persist the advisory recommendation, then use `bootstrap/apply-starter-blueprint.sh <target-repo> --list` or `--blueprint ...` to explicitly choose and apply the blueprint before broad implementation begins.
- Explicit blueprint application should project into the first repo-local operating surfaces, not just the brief: review `PLAN.md`, `TEST_STRATEGY.md`, `ARCHITECTURE_NOTES.md`, `TODO.md`, and `WHERE_LEFT_OFF.md` immediately after applying.
- Keep runtime code separate from `_system/`.
