# System Orchestration Guide

This document is the **single orientation layer** for AIAST: how major surfaces relate, **what to read in which situation**, **how to validate and review** work in a sensible order, and **where to go** to expand, improve, or resolve conflicts—without replacing the dedicated contracts each topic already has.

## Who should read this

- **New agents or maintainers** who need one map before diving into `LOAD_ORDER.md` tiers.
- **Anyone consolidating** hooks, prompts, CI, plugins, or host adapters and needing a checklist.
- **Anyone unsure which file to update** when behavior spans multiple domains.

If you only have budget for three files after `AGENTS.md`, use: `INSTRUCTION_PRECEDENCE_CONTRACT.md`, `CONTEXT_INDEX.md`, `LOAD_ORDER.md`.

## How the core surfaces relate

| Surface | Role |
|--------|------|
| `CONTEXT_INDEX.md` | Human-readable **map** of domains (quality, security, coordination, etc.). |
| `LOAD_ORDER.md` | **Tiered startup sequence** when context is scarce. |
| `KEY.md` | **Exhaustive** per-file “what it is / when to load” (generated; do not hand-edit). |
| `SYSTEM_REGISTRY.json` | Machine-readable **inventory** of managed files for tooling and awareness checks. |
| `instruction-precedence.json` | Machine-readable **precedence** companion to the precedence contract. |
| `REPO_OPERATING_PROFILE.md` | Compact **ingestion** summary for hosts that cannot read the whole tree. |
| `MASTER_SYSTEM_PROMPT.md` | Shared **behavioral** contract for principal agents. |
| `AGENT_DISCOVERY_MATRIX.md` | Which **tool adapters** load which shared files. |
| `HOOK_AND_ORCHESTRATION_INDEX.md` | Map of **Cursor/CI/plugins/MCP** and related validators. |

Nothing in this guide overrides `INSTRUCTION_PRECEDENCE_CONTRACT.md`. When instructions conflict, follow that contract first, then `STANDARDS_CONFLICT_RESOLUTION.md` and `INSTRUCTION_CONFLICT_PLAYBOOK.md` as needed.

## Recommended read order (agents)

1. **Contract and truth:** `AGENTS.md` (or repo-local equivalent) → `INSTRUCTION_PRECEDENCE_CONTRACT.md` → `REPO_OPERATING_PROFILE.md` → `PROJECT_PROFILE.md`.
2. **Orientation:** `CONTEXT_INDEX.md` → skim this file → `LOAD_ORDER.md` Tier 0.
3. **Execution behavior:** `MASTER_SYSTEM_PROMPT.md` → `EXECUTION_PROTOCOL.md` → `MULTI_AGENT_COORDINATION.md` when more than one actor touches the repo.
4. **Current slice:** `WHERE_LEFT_OFF.md`, `TODO.md`, `FIXME.md`, `PLAN.md` as applicable.
5. **Domain depth:** use `CONTEXT_INDEX.md` and `KEY.md` to pull only what the task needs (security, packaging, MCP, etc.).

## Recommended review and validation order (before merge / release)

Order is **tighten then broaden**: local scripts first, then cross-checks, then handoff quality.

1. **Instruction layer:** `bootstrap/validate-instruction-layer.sh` (when you changed prompts, rules, or precedence-related files).
2. **System integrity:** `bootstrap/validate-system.sh . --strict` from the repo root that contains `_system/`.
3. **Conflicts:** `bootstrap/detect-instruction-conflicts.sh . --strict`.
4. **Awareness:** `bootstrap/check-system-awareness.sh .` (structural references and discovery consistency).
5. **Delivery alignment:** `bootstrap/check-delivery-gate-alignment.sh` (docs and gates stay aligned).
6. **Doctor sweep:** `bootstrap/system-doctor.sh .` for consolidated health signals.
7. **Handoff quality:** `HANDOFF_PROTOCOL.md`, `WHERE_LEFT_OFF.md`, evidence discipline per `PROVENANCE_AND_EVIDENCE.md` and `HALLUCINATION_DEFENSE_PROTOCOL.md`.

Formal criteria live in `VALIDATION_GATES.md` and milestone checklists in `DELIVERY_GATES.md`. Autonomous schedules and guardrails: `AUTONOMOUS_GUARDRAILS_PROTOCOL.md` and `bootstrap/run-autonomous-guardrails.sh`.

## Expansion and improvement (where to edit)

| Goal | Primary documents |
|------|-------------------|
| **Evolve the operating system** (new contracts, tiers, governance) | `SYSTEM_EVOLUTION_POLICY.md`, `UPGRADE_AND_DRIFT_POLICY.md`, `INSTALLER_AND_UPGRADE_CONTRACT.md` |
| **Keep the template reusable** | `TEMPLATE_NEUTRALITY_POLICY.md` |
| **Add examples or patterns** | `GOLDEN_EXAMPLES_POLICY.md`, `golden-examples/PATTERN_INDEX.md` |
| **Add prompts, packs, or skills** | `PROMPTS_INDEX.md`, `SKILLS_INDEX.md`, `PROMPT_EMISSION_CONTRACT.md`, `PROMPT_SYSTEM_BUILD_STANDARD.md` |
| **Add hooks, CI, plugins, MCP** | `HOOK_AND_ORCHESTRATION_INDEX.md`, `PLUGIN_CONTRACT.md`, `MCP_CONFIG.md` |
| **Change tool entry/adapters** | `HOST_ADAPTER_POLICY.md`, `bootstrap/generate-host-adapters.sh` |
| **Ship installers / multi-host validation** | `AGENT_INSTALLER_AND_HOST_VALIDATION_PROTOCOL.md`, `CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md` |
| **Ship polished product UX** (web, desktop, mobile) | `DESIGN_EXCELLENCE_FRAMEWORK.md`, `MODERN_UI_PATTERNS.md`, `design-system/THEME_GOVERNANCE.md`, `ACCESSIBILITY_STANDARDS.md`, `MOBILE_GUIDE.md` |

After **adding, renaming, or removing** managed files under `_system/`, `bootstrap/`, etc., regenerate inventory and keys per `SYSTEM_AWARENESS_PROTOCOL.md` (`generate-system-registry.sh`, `generate-system-key.sh`) and refresh integrity when your process requires it (`verify-integrity.sh --generate`).

## Optimization and efficiency

- **Context budgeting:** `CONTEXT_BUDGET_STRATEGY.md`, `context-budget-profiles.json`.
- **Optional concise assistant output (opt-in):** `.cursor/skills/concise-communication/SKILL.md` and `.cursor/commands/concise-session.md` — reduces **output** tokens when explicitly requested; not a default (handoff and requirements stay protected per the skill).
- **Optional long prose compression for input (opt-in):** `.cursor/skills/compress-context-input/SKILL.md`, `.cursor/commands/compress-context.md`, and `bootstrap/compress-context-file.sh` — for human-edited markdown under `docs/` / `notes/` only; tiered loading stays primary; see `CONTEXT_BUDGET_STRATEGY.md`.
- **Runtime and cost discipline:** `PERFORMANCE_BUDGET.md`, `AGENT_PERFORMANCE_GUIDE.md`.
- **Prompt quality over time:** `PROMPT_EFFECTIVENESS_TRACKING.md`.

## Conflict and ambiguity

- **Precedence:** `INSTRUCTION_PRECEDENCE_CONTRACT.md`, `instruction-precedence.json`.
- **Standards collisions:** `STANDARDS_CONFLICT_RESOLUTION.md`.
- **Procedural resolution:** `INSTRUCTION_CONFLICT_PLAYBOOK.md`.
- **Unsafe or unclear user requests:** `REQUEST_ALIGNMENT_PROTOCOL.md`.

## Multi-agent and continuity

- **Turn-taking and ownership:** `MULTI_AGENT_COORDINATION.md`, `AGENT_ROLE_CATALOG.md`.
- **Checkpoints:** `CHECKPOINT_PROTOCOL.md`.
- **Resume:** `WHERE_LEFT_OFF.md` (primary), `HANDOFF_PROTOCOL.md`.

## When not to use this file

- **Deep domain work** (threat modeling, packaging law, MCP server selection): read the dedicated guide from `CONTEXT_INDEX.md` instead of relying on this summary.
- **Replacing** `LOAD_ORDER.md` or `KEY.md`—this guide **points** to them; it does not duplicate their full sequences or catalog.

## Related one-pagers

- `QUICKSTART.md` — fastest human onboarding.
- `TROUBLESHOOTING.md` — when validation or doctors fail.
- `WORKING_FILES_GUIDE.md` — roles of planning and continuity files at repo root and under `_system/context/`.
- `PROMPTS_INDEX.md` — prompt templates, packs, and emission rules.
- `SKILLS_INDEX.md` — Cursor skill workflows aligned with roles.
- `bootstrap/README.md` — what each bootstrap script does (from repo root).
