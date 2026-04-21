# Release Notes

Use this file for the current candidate release or milestone summary.

## Current release target

- Target label: AIAST **1.23.0**
- Intended audience: AIAST maintainers, downstream app-repo agents, and operators who want cross-agent resume safety after rate limits, crashes, or deliberate handoffs
- Release goal: ship a first-class, agent-neutral mid-session checkpoint capability into the installable template so any agent (Claude, Codex, Cursor, Gemini, Windsurf, DeepSeek, Cline, Continue, Aider, PearAI, local models, or a human) can resume cleanly from whoever was interrupted — and harden `bootstrap/update-template.sh` against its own self-modification hazard.
- Release confidence: high after `_TEMPLATE_FACTORY/run-maintainer-lane.sh` → `maintainer_lane_ok`, `_TEMPLATE_FACTORY/run-automation-lane.sh` → `automation_lane_ok`, and `bootstrap/system-doctor.sh TEMPLATE --strict` → `system_doctor_ok` on the master source tree on 2026-04-14
- **Tag status (source repo):** annotated tag **`v1.23.0`** marks this minor release once the release commit lands on `main`.

## User-visible changes

- **New `bootstrap/write-checkpoint.sh` and `bootstrap/resume-from-checkpoint.sh`:** agent-neutral writer and reader for mid-session resume checkpoints under `_system/checkpoints/`. Five kinds (`session-start`, `mid-task`, `handoff`, `rate-limit-save`, `milestone`), JSON + Markdown pair, append-only history, atomic writes, no new runtime dependencies.
- **Expanded `_system/CHECKPOINT_PROTOCOL.md`:** mid-session semantics, required fields, writing and reading examples, rules, and the relationship between checkpoints, `WHERE_LEFT_OFF.md`, and `HANDOFF_PROTOCOL.md`.
- **New `_system/checkpoints/README.md`:** seed doc that ships with every installed downstream, describing the checkpoint directory layout and rules.
- **Startup wiring:** `_system/CONTEXT_INDEX.md`, `_system/LOAD_ORDER.md`, `_system/MASTER_SYSTEM_PROMPT.md`, and `_system/SYSTEM_AWARENESS_PROTOCOL.md` now instruct every agent to run `bash bootstrap/resume-from-checkpoint.sh .` on cold start, to write a checkpoint before stopping for any reason, and to persist a `rate-limit-save` before any command that could exhaust the remaining token/time budget.
- **Hardened `bootstrap/update-template.sh`:** a new re-exec guard detects drift between the installed and source copies of the script and re-execs from a stable tempfile before touching any managed files, closing the bash self-modification bug that could corrupt the running parser mid-refresh. Guarded by `AIAST_UPDATE_REEXEC` against infinite re-exec loops, with an `EXIT` trap that cleans up the tempfile.
- **New `cross_agent_checkpointing` capability flag** and `checkpoint_protocol`, `checkpoint_writer`, `checkpoint_reader`, `checkpoints_directory` markers in `_system/aiaast-capabilities.json`.

## Upgrade or migration notes

- Existing downstream repos pick up this release through `bootstrap/update-template.sh --refresh-managed --strict`. A repo that is still running the pre-fix installed copy of the update script should run the **source** template's script once to clear the self-modification hazard; subsequent upgrades can use the installed copy because the re-exec guard is now part of the managed surface.
- The new `_system/checkpoints/` directory is created empty on install — `LATEST.json`, `LATEST.md`, and files under `history/` are runtime artifacts written by whichever agent runs first. The awareness check does not require them to exist at install time.
- No breaking runtime API changes. The checkpoint slice is purely additive capability; all prior validators, generators, and governance surfaces continue to work unchanged.

## Known limitations

- The maintainer lane currently writes its checkpoint under `_META_AGENT_SYSTEM/checkpoints/` by direct file edit rather than via `bootstrap/write-checkpoint.sh`. A dedicated maintainer-side wrapper is a follow-up; until it ships, read maintainer checkpoints by opening `LATEST.md` directly.
- Template `PLAN.md` / `FIXME.md` remain neutral until replaced in a real product repo.
- Downstream repos still need their own repo-local proof after upgrade; passing the source-template automation lane does not replace app-specific validation.
