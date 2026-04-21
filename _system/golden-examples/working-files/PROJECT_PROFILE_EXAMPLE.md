# Project Profile Example

This is a neutral quality-bar example for `_system/PROJECT_PROFILE.md`. Replace every placeholder with repo-local truth.

## Completion status

- [x] Identity filled
- [x] Runtime boundaries filled
- [x] Stack filled
- [x] Components filled
- [x] Build, packaging, and install filled
- [x] Mobile and AI filled
- [x] Validation commands filled
- [x] Operations and deployment filled
- [x] Security and compliance filled
- [x] Observability filled
- [x] Constraints filled
- [x] MCP plan filled
- [x] Canonical docs filled
- [x] Experience targets filled
- [x] Release model filled

## Identity

- App name: [App name]
- App id: [reverse-domain app id or not-applicable note]
- Desktop entry id: [desktop id or not-applicable note]
- Android application id: [android id or not-applicable note]
- Repo purpose: [one clear sentence about what the product is for]
- Product category: [category]
- Primary users: [who uses it]
- Main workflows: [3-6 high-value workflows]
- Primary success criteria: [truthful, measurable outcome]
- Non-goals: [what the repo should not become]

## Runtime boundaries

- Runtime code roots: `src/`, `app/`, `client/`, or the actual roots
- Test roots: `tests/`, `src/**/__tests__/`, or the actual roots
- Scripts / tooling roots: `scripts/`, `bootstrap/`, or the actual roots
- Packaging / deploy roots: `packaging/`, `ops/`, `docker/`, or the actual roots
- Infrastructure roots: `infra/`, `.github/`, `docker/`, or the actual roots
- Agent-system root: `_system/`
- No-touch zones: generated artifacts, archives, vendored assets, or any repo-local surfaces that should not be hand-edited

## Stack

- Primary languages: [languages]
- Primary frameworks: [frameworks]
- Components: [key UI/runtime component stacks]
- Datastores: [datastores]
- Package managers: [package managers]
- Build tools: [build and compilation tools]
- Runtime environments: [runtime environments]
- Supported environments: [host or browser environments]
- Deployment targets: [local, cloud, packaged, etc.]

## Build and packaging

- Packaging targets: [web, desktop, mobile, container, etc.]
- Native package targets: [AppImage, deb, rpm, none, etc.]
- Universal package targets: [web, container, none, etc.]
- Packaging manifest paths: [actual manifest paths]
- Installer commands: [actual installer commands]
- Signing identity: [real signer or explicit placeholder if not ready]
- Minimum runtime versions: [runtime versions]
- System dependencies: [host dependencies]
- Build entrypoints: [actual build commands]
- Release artifacts: [what gets shipped]

## Validation commands

- Format: [command]
- Lint: [command]
- Typecheck: [command]
- Unit tests: [command]
- Integration tests: [command]
- End-to-end or smoke: [command]
- Build: [command]
- Install / launch verification: [command]
- Packaging verification: [command]
- Visual regression or design smoke: [command]
- Security or policy checks: [command]

## Mobile and AI

- Mobile targets: [targets or not-applicable]
- Android module path: [path or not-applicable]
- Mobile release artifacts: [artifacts or not-applicable]
- Mobile build flavors: [flavors or not-applicable]
- LLM config path: [path or not-applicable]
- Default LLM provider: [provider or provider-agnostic note]
- Chatbot surfaces: [surfaces]
- Command bus or action registry: [path or concept]
- Local documentation sources: [docs paths]

## Operations and deployment

- Default ports: [ports or not-applicable]
- Default port range: [range]
- Bind model: [loopback-only, configurable, etc.]
- Required background services: [services]
- Service model: [monolith, worker set, detached local runtime, etc.]
- Migration model: [how schema or runtime migrations land]
- Database mode: [single-node, local-first, cloud-managed, etc.]
- Container runtime preference: [docker, podman, none]
- Service account model: [how privileged runtime actions are scoped]
- Required env vars: [real required vars]
- Optional providers: [optional integrations]
- Known degraded modes: [truthful failure modes]
- Backup location: [backup path or policy]
- Filesystem layout: [key persistent paths]
- Environment files: [actual env files]
- Reverse proxy or ingress: [actual ingress model]

## Security and compliance

- Safety / compliance: [non-negotiable safeguards]
- Security: [real security expectations]
- Secret handling: [where secrets live]
- Data classification: [what data is sensitive]
- Audit or retention requirements: [actual requirements]
- Threat model doc: [path]

## Observability

- Structured logging surface: [path or endpoint]
- Metrics surface: [endpoint or none]
- Health or readiness surface: [endpoint or script]
- Tracing or profiling surface: [tooling or none]
- Alerting or dashboards: [tooling or none]

## Constraints

- Performance: [real budgets or expectations]
- UI / design: [quality bar]
- Accessibility expectations: [specific standard]
- Data integrity: [canonical data guarantees]
- Release / packaging: [release discipline]
- Repo workflow: [branching, diff size, handoff rules]
- Compatibility requirements: [browser, OS, API, or provider constraints]

## MCP plan

- Project-scoped servers: [allowed servers]
- User-level shared servers: [optional shared servers]
- Read-only defaults: [what default access should be]
- Elevation rules: [when mutation is allowed]
- Servers to avoid: [what must stay out]

## Canonical docs

- Product spec: [path]
- Architecture: [path list]
- Data model: [path list]
- Runbook: [path list]
- Standards: [path list]
- Threat model: [path]
- Additional design docs: [path list]

## Experience targets

- Visual quality bar: [product-quality description]
- Interaction quality bar: [interaction-quality description]
- Performance quality bar: [performance bar]
- Accessibility expectations: [accessibility bar]
- Device targets: [devices]
- Brand or tone constraints: [tone]

## Release model

- Environments: [environments]
- Branch strategy: [strategy]
- Rollout method: [how release happens]
- Backout method: [rollback]
- Release signoff: [real signoff]
- Post-release verification: [real verification]

## High-value conventions

- Naming conventions: [naming rules]
- Module boundary rules: [boundary rules]
- Logging rules: [logging rules]
- Testing rules: [testing expectations]
- Handoff expectations: [how continuity is maintained]
- Documentation update expectations: [what must be updated with code changes]
