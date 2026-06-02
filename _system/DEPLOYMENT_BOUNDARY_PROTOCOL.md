# Deployment Boundary Protocol

This protocol clarifies the boundary between the meta-system and application code at deployment time, and defines what travels with the deployed application.

## Core principle

**Runtime application code must not depend on or reference the `_system/` directory.**

The `_system/` directory is an **agent operating layer** — it governs how agents build, test, and maintain the application, but it does NOT ship with the deployed application.

## File classification

### Category A: Agent Operating Layer (stays in `_system/`, does not deploy)

These files guide agents and are removed or neutralized before deployment:

- `AGENTS.md` — Agent rules and operating contracts.
- `_system/` — Entire directory with governance, policies, and contracts.
- `.claude/`, `.cursor/`, `.gemini/`, etc. — Tool-specific adapter folders (optional; may be removed or neutralized).
- Tool overlays and plugins (unless explicitly part of the application).
- Local orchestration scripts (`bootstrap/`, `scripts/` with agent-specific commands).
- Session artifacts (`.copilot/`, `.cursor/plans/`, handoff notes, etc.).

**Deployment action:** Remove or archive these directories. They are not shipped to production.

### Category B: Project Documentation (may deploy conditionally)

These files document the project and may ship depending on deployment context:

- `PRODUCT_BRIEF.md` — What the application does. Usually ships as part of project documentation.
- `DESIGN_NOTES.md`, `ARCHITECTURE_NOTES.md` — Design decisions. Optional; may ship or stay in repo only.
- `ROADMAP.md`, `RESEARCH_NOTES.md` — Planning artifacts. Optional; usually stays in repo only.
- `TODO.md`, `FIXME.md` — Work tracking. Usually stays in repo only; does not ship.
- `README.md` — Application overview. Usually ships.
- `CHANGELOG.md` — Release history. Usually ships or integrates into deployment docs.

**Deployment action:** Decide per-application which docs to include in deployment (e.g., ship `README.md` and `CHANGELOG.md` in the tarball, but leave `TODO.md` in the repo only).

### Category C: Runtime Application Code (deploys as-is)

These files are the actual application and must NOT reference `_system/`:

- `src/`, `app/`, `lib/`, `bin/` — Application source code.
- `config/`, `static/`, `templates/` — Application assets and configuration.
- `tests/`, `spec/` — Tests (may ship depending on deployment model).
- `package.json`, `requirements.txt`, `Cargo.toml`, etc. — Dependency manifests.
- `dist/`, `build/` — Build artifacts.
- `.env.example` — Environment variable templates (sanitized, no secrets).

**Deployment action:** Deploy as-is. These files MUST NOT import or reference `_system/`.

### Category D: Runtime Support (deploys conditionally)

These files support the running application:

- `.gitignore` — Deployment-safe (no agent-specific patterns removed).
- `.dockerignore`, `.npmignore`, etc. — Deployment configuration (safe).
- Deployment scripts in `scripts/` (e.g., `scripts/start.sh`, `scripts/deploy.sh`) — Deploy if needed.
- `docker/`, `kubernetes/`, `.github/workflows/` — Deployment infrastructure. Deploy as-is.
- CI/CD configs (`.github/workflows/`, `.gitlab-ci.yml`, etc.) — May deploy or stay in repo only.

**Deployment action:** Review per-application. Remove agent-specific CI (e.g., `bootstrap/check-*.sh` invocations), keep application-critical CI.

### Category E: Version Control (always stays in repo)

These files track repository state:

- `.git/` — Always stays in repo; may be stripped for deployment snapshots.
- `.gitignore` — Stays in repo and deployment.
- Git hooks and related configs — Usually stay in repo only; rarely deploy to production.

**Deployment action:** Keep `.git/` in the source repo; optionally include in development distributions but not in production builds.

### Category F: Vendor/Tool Artifacts (usually ignored)

These are typically generated or vendor-specific:

- `node_modules/`, `.venv/`, etc. — Generated from dependency manifests; never deployed from repo.
- Build artifacts (`.o`, `.pyc`, etc.) — Generated during build; never committed.
- Editor configs (`.vscode/`, `.idea/`, etc.) — Editor-specific; safe to include or strip.

**Deployment action:** Use `.gitignore` to exclude from repo; regenerate during deployment if needed.

## Deployment workflow

### Pre-deployment checklist

Before deploying:

1. **Audit runtime code:** Verify no `src/`, `app/`, `lib/` files reference `_system/`.
   ```bash
   grep -r "_system" src/ app/ lib/ --exclude-dir=.git 2>/dev/null && echo "❌ FAIL: Runtime code references _system/" || echo "✓ PASS"
   ```

2. **Identify deployment scope:** Decide which files/dirs to include in the deployment artifact (tarball, container, etc.).

3. **Strip agent operating layer:** Remove or archive:
   - `_system/` directory
   - `.claude/`, `.cursor/`, `.gemini/`, etc. (or keep if development distribution)
   - `AGENTS.md`, bootstrap scripts
   - Session artifacts

4. **Neutralize local configs:** Remove secrets and local paths:
   - `.env` (keep `.env.example` only)
   - Any local credentials or API keys
   - Local build paths or debug flags

5. **Test the deployment artifact:** Unpack and verify the application runs without `_system/` present.

### Deployment artifact structure

A typical deployed application looks like:

```
my-app/
├── README.md                 ← Deployed (documentation)
├── LICENSE                   ← Deployed
├── CHANGELOG.md              ← Deployed (optional)
├── .gitignore                ← Deployed (safe)
├── package.json              ← Deployed (runtime)
├── docker/                   ← Deployed (optional)
├── src/                       ← Deployed (runtime)
├── lib/                       ← Deployed (runtime)
├── tests/                     ← Deployed (optional)
├── config/                    ← Deployed (runtime)
├── .env.example               ← Deployed (safe, no secrets)
│
├── [NOT in deployment]
├── _system/                   ← STRIPPED (agent operating layer)
├── AGENTS.md                  ← STRIPPED
├── .claude/, .cursor/         ← STRIPPED
├── bootstrap/                 ← STRIPPED
├── PRODUCT_BRIEF.md          ← Optional (removed or in docs)
├── DESIGN_NOTES.md           ← Optional (removed or in docs)
├── TODO.md                    ← STRIPPED
├── WHERE_LEFT_OFF.md         ← STRIPPED
└── .env                       ← STRIPPED (secrets)
```

### Container/Docker example

In a `Dockerfile`:

```dockerfile
FROM node:20-alpine

WORKDIR /app

# Copy only runtime files
COPY package.json package-lock.json ./
COPY src/ ./src/
COPY config/ ./config/
COPY lib/ ./lib/

# Install production dependencies
RUN npm ci --only=production

# Do NOT copy _system/, AGENTS.md, .claude/, etc.

EXPOSE 3000
CMD ["node", "src/index.js"]
```

### Archive/Tarball example

When creating a source distribution:

```bash
# Include runtime + development docs
tar --exclude='_system' \
    --exclude='.claude' \
    --exclude='.cursor' \
    --exclude='AGENTS.md' \
    --exclude='bootstrap' \
    --exclude='TODO.md' \
    --exclude='WHERE_LEFT_OFF.md' \
    --exclude='.env' \
    -czf my-app-1.0.0.tar.gz \
    -C .. my-app/

# Verify deployment artifact
tar -tzf my-app-1.0.0.tar.gz | grep -E '_system|AGENTS.md|bootstrap' || echo "✓ Clean"
```

## Runtime code rules

### What runtime code CAN do

- Import from `src/`, `lib/`, `app/`.
- Read from `config/`, `static/`, `templates/`.
- Load from `node_modules/` or equivalent.
- Read environment variables from `.env` (loaded at runtime, not in code).
- Read from data stores, caches, or external services.

### What runtime code CANNOT do

- `require('../../_system/...')` or `import _system from '_system'`.
- Reference `AGENTS.md` or operating-layer files.
- Call `bootstrap/check-*.sh` or agent scripts at runtime.
- Depend on the presence of tool adapter folders (`.claude/`, etc.).
- Assume agent orchestration is available in production.

### Validation

Linters and pre-deploy validators MUST enforce this:

```bash
#!/bin/bash
# Check for runtime code referencing _system
if grep -r "require.*_system\|import.*_system\|from.*_system" \
         src/ app/ lib/ --include="*.js" --include="*.ts" --include="*.py" 2>/dev/null; then
    echo "❌ FAIL: Runtime code references _system/"
    exit 1
else
    echo "✓ PASS: No runtime dependencies on _system/"
fi
```

## Special cases

### Monorepo deployments

If the repo contains multiple applications or packages:

1. Each application `app1/`, `app2/`, etc. MUST be independently deployable.
2. Each app has its own deployment artifact (tarball, container, etc.).
3. The shared `_system/`, `AGENTS.md` stay in the repo only (not deployed).
4. Shared libraries in `lib/`, `packages/` are runtime code (deployed with all apps).

### Development vs. production distributions

- **Development distribution** (for developers): Include `_system/`, `AGENTS.md`, `bootstrap/`, `.claude/`, etc. so devs can use the full toolchain.
- **Production distribution** (for end users/servers): Strip agent operating layer; include only runtime code, docs, and config.

### Configuration management

- `_system/` may contain environment-agnostic operating rules.
- `config/` directory contains runtime configuration (may vary per environment).
- Agents use both during development; production uses `config/` only.

## Summary

| File/Dir | Deployed? | Notes |
| --- | --- | --- |
| `src/`, `app/`, `lib/` | ✅ Yes | Runtime code; must not reference `_system/` |
| `config/` | ✅ Yes | Runtime configuration |
| `README.md`, `CHANGELOG.md` | ✅ Yes | Project documentation |
| `tests/` | ⚠️ Optional | Include if needed for development distribution |
| `docker/`, `.github/workflows/` | ✅ Yes (conditional) | Deployment infrastructure |
| `package.json`, requirements files | ✅ Yes | Dependency manifests |
| `_system/` | ❌ No | Agent operating layer only |
| `AGENTS.md` | ❌ No | Agent operating layer only |
| `.claude/`, `.cursor/`, etc. | ❌ No | Agent tool adapters only |
| `bootstrap/` | ❌ No | Agent build scripts only |
| `TODO.md`, `FIXME.md` | ❌ No | Work tracking (repo only) |
| `.env` | ❌ No | Secrets (never deployed); use `.env.example` |

---

**Effective date:** Effective immediately for all new scaffolds and build validations.
**Enforcement:** Pre-deployment checklist MUST pass before shipping.
