# Environment Validation Contract

Environment validation checks runtime prerequisites beyond AIAST file integrity.

## Scope

Environment validation covers:

1. **Required CLI tools** — tools declared in `PROJECT_PROFILE.md` (languages, package managers, build tools)
2. **Port availability** — ports declared in `PROJECT_PROFILE.md` operations section
3. **Environment variables** — variables declared in `ops/env/.env.example` if it exists
4. **Disk space** — minimum 500MB free in the repo root filesystem
5. **Database connectivity** — if a database is declared in the project profile

## Check levels

- **pass** — the prerequisite is satisfied
- **warn** — the prerequisite is missing but not blocking (optional tools, extra ports)
- **fail** — the prerequisite is missing and required for the declared stack

## Integration

- `bootstrap/check-environment.sh` performs all environment checks.
- `bootstrap/system-doctor.sh` includes environment checks at warn level by default.
- `bootstrap/generate-diagnostic-report.sh` includes environment state in reports.
- The observability-setup plugin uses the `environment.validate` hook for monitoring checks.

## Declaring requirements

Requirements are declared in `_system/PROJECT_PROFILE.md`:

- **Languages**: listed under "Languages and versions"
- **Package managers**: listed under "Package managers"
- **Build tools**: listed under "Build tools"
- **Ports**: listed under "Ports"
- **Database**: listed under "Database"
- **Runtime environments**: listed under "Runtime environments"

## Rules

- Environment checks must not modify the system. They are read-only probes.
- Missing optional tools produce warnings, not failures.
- Port checks verify availability, not whether a service is running.
- Database checks verify connectivity, not schema state.
- All check results are structured for machine consumption (JSON when `--json` is used).
