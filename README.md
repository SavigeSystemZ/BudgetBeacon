# Project Agent Operating System

This repo carries a self-contained, project-local AI operating system that governs how agents design, build, debug, test, review, package, secure, upgrade, and hand off work.

It is also designed to coexist with external host/orchestrator instruction layers without treating those layers as repo-local truth.

## Core idea

The repo gets its own local agent operating system instead of depending on one shared external folder. That keeps multiple apps isolated from each other while still using one master standard.

The master template intentionally includes app-shaped working files such as `PRODUCT_BRIEF.md`, `PLAN.md`, `DESIGN_NOTES.md`, and `TEST_STRATEGY.md`, but they stay generic here. Once installed into a real repo, those files become the app's local operating surface.

In the master AIAST source repo, maintainer-only design and planning state for AIAST itself lives outside the installable tree in a master-repo-only meta workspace so new app repos do not inherit template-maintenance context by accident.

## Version and lifecycle

- Human-readable release marker: `AIAST_VERSION.md`
- Installed version marker: `_system/.template-version`
- Compatibility marker: `_system/aiaast-capabilities.json`
- Install metadata: `_system/.template-install.json`
- Managed-file registry: `_system/SYSTEM_REGISTRY.json`
- Repo operating profile: `_system/REPO_OPERATING_PROFILE.md`
- Instruction precedence contract: `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`
- Upgrade policy: `_system/UPGRADE_AND_DRIFT_POLICY.md`

## Quick start

New to AIAST? Read `_system/QUICKSTART.md` for a 5-minute onboarding guide.

## Getting started

1. Fill in `_system/PROJECT_PROFILE.md`.
2. Turn `PRODUCT_BRIEF.md` into repo-specific truth so the product frame, quality bar, and first build shape are explicit.
3. If the repo is still greenfield, use `bootstrap/recommend-starter-blueprint.sh <target-repo> --write`, review the persisted recommendation, then use `bootstrap/apply-starter-blueprint.sh <target-repo> --list` or `--blueprint ...` to apply the chosen build shape before broad implementation begins.
4. Confirm the repo-local authority model in `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`.
5. Review `_system/REPO_OPERATING_PROFILE.md` before emitting host-level prompts or orchestration rules.
6. Confirm validation commands, packaging targets, deployment surfaces, and quality gates in the profile.
7. Use the seeded `TEST_STRATEGY.md` as the first-pass confidence model, then replace fallback lines with repo-proven lanes after the first real run.
8. Use the seeded `RISK_REGISTER.md` as a first-pass risk picture, then replace or delete seeded entries once repo-local evidence exists.
9. Configure project-scoped MCP entries from `_system/mcp/`.
10. Treat `_system/` as durable governance, not runtime code.
11. Use `_system/starter-blueprints/` when bootstrapping a new app.
12. Use `bootstrap/update-template.sh --dry-run` to preview future AIAST upgrades.
13. For any lifecycle command that accepts `--source`, point it at the canonical AIAST template root only, never at the master repo root or an already-installed app repo.
14. Use `bootstrap/check-install-boundary.sh` if you want an explicit proof that maintainer-only layers were not copied into the app repo.

## Agent entrypoints

Every agent loads `AGENTS.md` first, then uses its tool-specific adapter:

| Tool | Entrypoint |
|------|-----------|
| Claude | `CLAUDE.md` |
| Cursor | `.cursorrules` + `.cursor/` |
| Gemini | `GEMINI.md` |
| Codex | `CODEX.md` |
| Windsurf | `WINDSURF.md` + `.windsurfrules` |
| Copilot | `.github/copilot-instructions.md` |
| DeepSeek | `DEEPSEEK.md` |
| Aider | `.aider.conf.yml` |
| Continue.dev | `.continuerules` |
| Cline | `.clinerules` |
| PearAI | `PEARAI.md` |
| Local models | `LOCAL_MODELS.md` |

All adapters share the same core contract and load the same system files.

When a host/orchestrator wraps one of these tools, repo-local files still define repo truth and runtime boundaries.

## System layer (`_system/`)

### Governance and execution

- Master system prompt, project rules, execution protocol
- Multi-agent coordination, checkpoint protocol, validation gates
- Memory rules, working-file guide, template-neutrality policy
- Instruction precedence, repo operating profile, and prompt-emission contracts
- Upgrade, drift, integrity, observability, and plugin contracts

### Quality standards

- Coding standards
- Performance budgets
- Accessibility standards
- API design standards
- Dependency governance
- Modern UI patterns
- Design excellence framework

### Operations, security, and packaging

- Security, redaction, audit, and provenance rules
- self-awareness and hallucination-defense protocols
- systemd hardening guidance and generated unit support
- Packaging guides for native and universal Linux distribution
- Installation, mobile, and chatbot extension guides
- CI templates and release scaffolds
- Threat-model and observability surfaces

### Prompting

- Prompt templates
- Prompt packs
- Starter blueprints for common app shapes

### Durable context

- Context surfaces for status, decisions, memory, invariants, assumptions, integrations, questions, and debt

Nothing in `_system/` should be required for the app to run.

## Bootstrap helpers

- `bootstrap/init-project.sh` — install the system into a target repo
- `bootstrap/install-missing-files.sh` — add new template files without overwriting existing repo-owned state, then backfill missing runtime scaffolds and onboarding defaults
- `bootstrap/update-template.sh` — preview and apply AIAST upgrades, then re-run the same safe onboarding backfill path used during install
- `bootstrap/repair-system.sh` — restore drifted template-managed files
- `bootstrap/uninstall-system.sh` — remove the operating layer cleanly
- `bootstrap/seed-product-brief.sh` — convert profile signals into a first-pass repo-local `PRODUCT_BRIEF.md`
- `bootstrap/recommend-starter-blueprint.sh` — persist an advisory starter-blueprint recommendation with confidence and rationale
- `bootstrap/apply-starter-blueprint.sh` — stamp a selected starter blueprint into the first repo-local operating surfaces, including `PRODUCT_BRIEF.md`, `PLAN.md`, `DESIGN_NOTES.md`, `RISK_REGISTER.md`, `RELEASE_NOTES.md`, and related execution files
- `bootstrap/generate-system-registry.sh` — rebuild the AIAST managed-file registry
- `bootstrap/generate-operating-profile.sh` — emit the compact host-ingestion profile
- `bootstrap/check-system-awareness.sh` — verify registry and path-reference integrity
- `bootstrap/detect-instruction-conflicts.sh` — scan for overlapping or contradictory instruction layers
- `bootstrap/validate-instruction-layer.sh` — verify precedence, profile, and prompt-emission surfaces
- `bootstrap/check-hallucination.sh` — detect claim-evidence mismatches
- `bootstrap/check-install-boundary.sh` — fail if maintainer-only or foreign product layers leaked into the app repo
- `bootstrap/check-runtime-foundations.sh` — validate generated packaging, install, mobile, env, and AI scaffolds
- `bootstrap/system-doctor.sh` — run the full self-diagnosis suite
- `bootstrap/heal-system.sh` — run the self-diagnosis suite in auto-heal mode
- `bootstrap/validate-system.sh` — verify required files, config syntax, and portability
- `bootstrap/verify-integrity.sh` — hash-check template-managed files only
- `bootstrap/detect-drift.sh` — report version, integrity, and source drift
- `bootstrap/scan-security.sh` — run applicable dependency and container scanners
- `bootstrap/generate-systemd-unit.sh` — emit hardened systemd units
- `bootstrap/generate-runtime-foundations.sh` — emit project-owned packaging, install, mobile, logging, and AI scaffolds

## Generated runtime foundations

Fresh installs also receive project-owned runtime scaffolds outside `_system/`:

- packaging manifests for AppImage, Flatpak, and Snap
- ops install, repair, uninstall, purge, and port-allocation scaffolds
- ops environment and compose examples
- mobile Flutter starter files
- ai provider configuration and chatbot intent scaffolds

These files are intentionally app-owned after generation and should be adapted to the project runtime.

If those generated scaffolds or first-session continuity files are later deleted, `bootstrap/install-missing-files.sh` and `bootstrap/update-template.sh` now recreate the missing generated files and reseed safe onboarding defaults, including `PRODUCT_BRIEF.md`, without overwriting repo-owned edits.

Install metadata now also retains the repo app identity so lifecycle recovery can preserve the original app name even if early working files are temporarily missing.
