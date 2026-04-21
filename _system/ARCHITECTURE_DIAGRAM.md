# AIAST Architecture Diagrams

## Three-Layer Model

```
+--------------------------------------------------+
|              Application Repository               |
|                                                   |
|  +----------------------------------------------+ |
|  |  TEMPLATE/ (installable product)              | |
|  |                                               | |
|  |  AGENTS.md          <-- entry point           | |
|  |  CLAUDE.md, CODEX.md, GEMINI.md, ...         | |
|  |  .cursorrules, .windsurfrules, ...            | |
|  |  TODO.md, PLAN.md, WHERE_LEFT_OFF.md, ...    | |
|  |                                               | |
|  |  _system/           <-- governance layer      | |
|  |    PROJECT_PROFILE.md                         | |
|  |    MASTER_SYSTEM_PROMPT.md                    | |
|  |    PROJECT_RULES.md                           | |
|  |    VALIDATION_GATES.md                        | |
|  |    golden-examples/, plugins/, ...            | |
|  |                                               | |
|  |  bootstrap/          <-- lifecycle scripts    | |
|  |    validate-system.sh                         | |
|  |    system-doctor.sh                           | |
|  |    init-project.sh                            | |
|  +----------------------------------------------+ |
+--------------------------------------------------+

+--------------------------------------------------+
|  _TEMPLATE_FACTORY/ (master-repo only)            |
|    scaffold-repos.sh                              |
|    validate-master-template.sh                    |
|    run-automation-lane.sh                         |
|    smoke-*.sh                                     |
|    SOURCE_LIBRARY/                                |
+--------------------------------------------------+

+--------------------------------------------------+
|  _META_AGENT_SYSTEM/ (maintainer workspace)       |
|    PLAN.md, TODO.md, WHERE_LEFT_OFF.md            |
|    COMPLETION_SHEET.md                            |
|    context/                                       |
+--------------------------------------------------+
```

## File Loading Flow

```
Agent starts
    |
    v
[AGENTS.md] -- binding contract
    |
    v
[Tool adapter] -- CLAUDE.md / CODEX.md / .cursorrules / etc.
    |
    v
[Startup sequence from LOAD_ORDER.md]
    |
    +---> Tier 0: Operating contract (18 files)
    |       INSTRUCTION_PRECEDENCE_CONTRACT.md
    |       REPO_OPERATING_PROFILE.md
    |       MASTER_SYSTEM_PROMPT.md
    |       PROJECT_RULES.md
    |       ...
    |
    +---> Tier 1: Working state (18 files)
    |       WHERE_LEFT_OFF.md
    |       TODO.md, FIXME.md, PLAN.md
    |       context/*.md
    |       ...
    |
    +---> Tier 2: Execution references (20 files)
    |       VALIDATION_GATES.md
    |       CODING_STANDARDS.md
    |       ...
    |
    +---> Tier 3: Prompting and tooling (10+ items)
            prompt-packs/, review-playbooks/
            ...
```

## Adapter Generation Pipeline

```
host-adapter-manifest.json
    |
    v
generate-host-adapters.sh (Python renderer)
    |
    +---> CLAUDE.md      (render_generic)
    +---> CODEX.md       (render_generic)
    +---> GEMINI.md      (render_generic)
    +---> WINDSURF.md    (render_generic)
    +---> DEEPSEEK.md    (render_generic)
    +---> PEARAI.md      (render_generic)
    +---> LOCAL_MODELS.md (render_generic)
    +---> .cursorrules   (render_generic)
    +---> .windsurfrules (render_generic)
    +---> .continuerules (render_generic)
    +---> .clinerules    (render_generic)
    +---> .github/copilot-instructions.md (render_generic)
    +---> .aider.conf.yml (render_aider)
    +---> .cursor/*       (render_cursor_*)
    |
    v
check-host-adapter-alignment.sh (verify)
```

## Validation Chain

```
system-doctor.sh
    |
    +---> validate-system.sh ---- file existence, JSON/TOML syntax, version consistency
    +---> check-install-boundary.sh
    +---> verify-integrity.sh ---- SHA256 manifest
    +---> validate-instruction-layer.sh ---- adapter conflicts
    +---> check-host-adapter-alignment.sh
    +---> check-host-ingestion.sh
    +---> check-host-bundle.sh
    +---> check-system-awareness.sh ---- registry vs real files
    +---> check-agent-orchestration.sh
    +---> check-placeholders.sh (warn)
    +---> check-runtime-foundations.sh (warn/strict)
    +---> check-packaging-targets.sh (warn/strict)
    +---> check-hallucination.sh (warn)
    +---> check-environment.sh (warn) ---- runtime prerequisites
    +---> detect-drift.sh (info)
    +---> discover-plugins.sh (info) ---- plugin status
    |
    v
  system_doctor_ok / system_doctor_warn / system_doctor_failed
```

## Plugin Hook Lifecycle

```
Event trigger (e.g., bootstrap.post_install)
    |
    v
discover-plugins.sh ---- find all plugins
    |
    v
For each enabled plugin with matching hook:
    |
    +---> validate-plugin.sh ---- check manifest
    +---> run.sh <repo> <hook> ---- execute (separate process)
    |       |
    |       +---> exit 0: success
    |       +---> exit non-zero: warning (does not block)
    |
    v
Plugin results aggregated into diagnostic report
```

## Instruction Precedence

```
Highest priority                        Lowest priority
     |                                       |
     v                                       v
[Repo runtime]  >  [AIAST core]  >  [Tool overlay]  >  [Prompt emission]  >  [Host orchestration]
  actual code       AGENTS.md        CLAUDE.md          prompt-packs/        external host
  config files      PROJECT_RULES    .cursorrules       host-bundle          orchestrator
  schemas           MASTER_PROMPT    CODEX.md                                chat context
```
