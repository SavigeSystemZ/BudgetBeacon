# Python CLI Tool Blueprint

Use this when bootstrapping a Python command-line application.

## Expected repo shape

```
src/
  app_name/
    __init__.py
    __main__.py
    cli.py
    core/
    utils/
tests/
  test_cli.py
  test_core.py
pyproject.toml
README.md
```

## Stack signals

- Primary languages: Python
- Primary frameworks: click or typer for CLI, rich for output formatting
- Package managers: uv, pip, or poetry
- Build tools: hatchling, setuptools, or flit
- Runtime environments: Python 3.10+

## Validation commands

- Format: `ruff format --check .`
- Lint: `ruff check .`
- Typecheck: `mypy src/`
- Unit tests: `pytest -q`
- Build: `python -m build` or `uv build`
- Install verification: `pip install -e . && app-name --help`

## Quality expectations

- Use `pyproject.toml` for all project configuration. No `setup.py` or `setup.cfg`.
- Keep the `src/` layout shown above or set explicit package discovery in
  `pyproject.toml`. Do not rely on flat setuptools auto-discovery in scaffolded
  repos that already contain top-level `ops/`, `mobile/`, `packaging/`, or
  `ai/` directories.
- Type hints on all public functions and module boundaries.
- Structured CLI with subcommands, help text, and clear argument validation.
- Exit codes: 0 for success, 1 for user errors, 2 for system errors.
- Rich, human-readable output for interactive use. Machine-readable output (JSON, CSV) via `--format` flag.
- Proper signal handling (Ctrl+C graceful shutdown).
- Configuration via environment variables, config file, and CLI flags with clear precedence.
- Logging to stderr, output to stdout. Never mix logging and output.

## First milestone suggestion

- Confirm the package installs cleanly with `pip install -e .`.
- Confirm `--help` output is clear and complete.
- Confirm lint, format, and typecheck pass.
- Confirm at least one test per subcommand.
- Confirm exit codes are correct for success and failure cases.
