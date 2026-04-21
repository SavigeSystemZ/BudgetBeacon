# Troubleshooting

Common issues and their solutions, organized by symptom.

## Unsure where to start or which file to read

**Symptom**: Too many `_system/` documents; hard to pick a path before coding.

**Fix**:
1. Read `_system/SYSTEM_ORCHESTRATION_GUIDE.md` once for how surfaces connect, recommended review/validation order, and expansion pointers.
2. Follow `_system/LOAD_ORDER.md` for tiered loading when context is tight.
3. Use `_system/CONTEXT_INDEX.md` to jump to a domain (security, packaging, MCP, etc.).

## Agent ignores project rules

**Symptom**: Agent acts as if `_system/PROJECT_RULES.md` does not exist.

**Diagnosis**: The agent may not have loaded the startup sequence, or host-level instructions are overriding repo-local rules.

**Fix**:
1. Verify the agent loaded `AGENTS.md` first.
2. Check `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md` — repo-local truth wins.
3. Run `bootstrap/validate-instruction-layer.sh .` to check for adapter conflicts.
4. If using a host orchestrator, ensure it defers to repo-local files.

## Validation fails after upgrade

**Symptom**: `bootstrap/validate-system.sh . --strict` fails after updating AIAST.

**Fix**:
1. Run `bootstrap/install-missing-files.sh .` to add any new required files.
2. Run `bootstrap/system-doctor.sh . --heal` to auto-repair.
3. Run `bootstrap/detect-drift.sh . --source <template>` to see what drifted.
4. If version mismatch: check `AIAST_VERSION.md` matches `_system/.template-version`.

## Missing files after install

**Symptom**: `validate-system.sh` reports missing required files.

**Fix**:
1. Run `bootstrap/install-missing-files.sh . --source <template-root>`.
2. Run `bootstrap/repair-system.sh .` for safe file restoration.
3. Check that the source template is at the expected version.

## Agent hallucinates about features

**Symptom**: Agent claims something was tested/built/deployed when it was not.

**Fix**:
1. Run `bootstrap/check-hallucination.sh .` to detect claim-evidence mismatches.
2. Check `_system/HALLUCINATION_DEFENSE_PROTOCOL.md` for verification rules.
3. Verify `WHERE_LEFT_OFF.md` matches actual repo state.

## Adapter files are stale

**Symptom**: `check-host-adapter-alignment.sh` reports stale adapters.

**Fix**:
1. Run `bootstrap/generate-host-adapters.sh . --write` to regenerate from manifest.
2. Run `bootstrap/check-host-adapter-alignment.sh .` to verify.
3. Do not hand-edit adapter files — update the manifest instead.

## Delivery-gate alignment check fails

**Symptom**: `bootstrap/check-delivery-gate-alignment.sh`, `bootstrap/validate-system.sh`,
or `bootstrap/system-doctor.sh` fails with messages such as **Missing delivery-gate surface**,
**Context index missing required reference**, **Load order missing required reference**,
or **Master system prompt missing** (request-alignment or guardrails installer).

**Diagnosis**: Contract files exist on disk but are not discoverable through
`_system/CONTEXT_INDEX.md`, `_system/LOAD_ORDER.md`, and `_system/MASTER_SYSTEM_PROMPT.md`,
or a required file was removed during a manual merge.

**Fix**:
1. Ensure these files exist: `_system/DELIVERY_GATES.md`, `_system/AI_RULES.md`,
   `_system/REPO_CONVENTIONS.md`, `_system/SECURITY_BASELINE.md`,
   `_system/REQUEST_ALIGNMENT_PROTOCOL.md`, `_system/AUTONOMOUS_GUARDRAILS_PROTOCOL.md`
   (run `bootstrap/install-missing-files.sh . --source <template-root>` if any are absent).
2. Add the missing filename tokens to `_system/CONTEXT_INDEX.md` and `_system/LOAD_ORDER.md`
   so each contract appears in both (copy the pattern from a fresh template export if unsure).
3. In `_system/MASTER_SYSTEM_PROMPT.md`, keep references to
   `REQUEST_ALIGNMENT_PROTOCOL.md` and `install-autonomous-guardrails.sh` as required by the checker.
4. Re-run `bash bootstrap/check-delivery-gate-alignment.sh . --strict`, then
   `bash bootstrap/validate-system.sh . --strict`.

## Copilot overlay becomes a broken symlink

**Symptom**: `.github/copilot-instructions.md` is a broken symlink (for example
`../TEMPLATE/.github/copilot-instructions.md`) and strict validation fails.

**Fix**:
1. Remove the broken link: `rm -f .github/copilot-instructions.md`
2. Regenerate adapters: `bash bootstrap/generate-host-adapters.sh . --write`
3. Re-run: `bash bootstrap/validate-system.sh . --strict`

## Plugin fails

**Symptom**: A plugin produces errors during system-doctor runs.

**Fix**:
1. Run `bootstrap/validate-plugin.sh _system/plugins/<name>` to check manifest.
2. Plugin failures are warnings, not fatal errors.
3. Set `"enabled": false` in `plugin.json` to disable a broken plugin.

## Environment check warns about missing tools

**Symptom**: `check-environment.sh` warns about tools referenced in profile.

**Fix**:
1. Install the missing tools, or
2. Remove the tool references from `_system/PROJECT_PROFILE.md` if not needed.
3. Stack-specific tools are warnings, not failures.

## Context too large for my model

**Symptom**: Small-context model cannot load the full startup sequence.

**Fix**:
1. Use `bootstrap/emit-tiered-context.sh . --model <model-name>` for appropriate tier.
2. See `_system/CONTEXT_BUDGET_STRATEGY.md` for tier definitions.
3. Adapters for local models (`LOCAL_MODELS.md`) reference the fast-path automatically.
4. **After** tiering: if a single long **human-authored** file under `docs/` or `notes/` still dominates input tokens, you may use **opt-in** compression (see **compress-context-file refuses my path or will not run** below)—never as a substitute for loading fewer contract files.

## compress-context-file refuses my path or will not run

**Symptom**: Running `bootstrap/compress-context-file.sh . <path> [--dry-run]` prints `REFUSED` or exits with a “not found” / `claude` / caveman error.

**Diagnosis (v1 safety model)**:
- The wrapper **only** allows paths under the repo’s top-level **`docs/`** or **`notes/`** trees, with extensions **`.md`**, **`.txt`**, or **`.rst`**. Everything else is rejected so generated host adapters (`CLAUDE.md`, `.cursorrules`, …), **`_system/`**, **`bootstrap/`**, **`.cursor/`**, and validate-system contract files are never compressed by default.
- Real compression delegates to upstream **[caveman-compress](https://github.com/JuliusBrussee/caveman/tree/main/caveman-compress)** (MIT): its Python entrypoint runs **`claude --print`** with prompts that ask the model to shorten **natural language** while preserving code fences, paths, and URLs; it writes a backup **`*.original.md`** beside the file and validates output. **No `claude` CLI on `PATH`** → the wrapper exits with install instructions.
- This is **input** compression (shrinking files you load). It is **not** the same as **`/concise-session`** / **`concise-communication`**, which shorten **assistant output** only.

**Fix**:
1. Move or copy the content into **`docs/...`** or **`notes/...`** (or split: keep contracts in `_system/`, keep long prose here).
2. Run a denylist-safe check first:
   ```bash
   ./bootstrap/compress-context-file.sh . docs/YOURFILE.md --dry-run
   ```
3. Install upstream tooling: copy **`caveman-compress`** to `~/.claude/skills/caveman-compress`, **or** set **`CAVEMAN_COMPRESS_HOME`** to that directory, **or** (master AIAST clone) rely on **`_TEMPLATE_FACTORY/third_party/caveman-compress`**. Install the **Anthropic Claude Code** CLI so **`claude`** is on **`PATH`**.
4. Run without **`--dry-run`** as a non-root repo owner:
   ```bash
   ./bootstrap/compress-context-file.sh . docs/YOURFILE.md
   ```
5. In **Cursor**, trigger the workflow with **`/compress-context`** (command: `.cursor/commands/compress-context.md`) and follow the same dry-run → compress → validate sequence.
6. After any successful run: **`./bootstrap/validate-system.sh . --strict`**, **`./bootstrap/check-system-awareness.sh .`**, then **review the diff**; rollback with **`git checkout -- <path>`** or the **`*.original.md`** backup if anything regressed.

## Multi-agent conflicts

**Symptom**: Two agents edit the same files, causing conflicts.

**Fix**:
1. Check `_system/MULTI_AGENT_COORDINATION.md` — single active writer model.
2. Read `WHERE_LEFT_OFF.md` to see if another agent left unfinished work.
3. Follow the takeover protocol: verify state before building on it.

## System awareness reports managed files missing from registry

**Symptom**: `bootstrap/check-system-awareness.sh` or `validate-system.sh --strict`
fails with `Managed file missing from registry` for paths under `.github/`,
`.cursor/`, or other scanned trees.

**Diagnosis**: `aiaast_print_managed_files` includes every file under `.github/` when
that directory exists. `_system/SYSTEM_REGISTRY.json` must list the same set. After
adding or copying new GitHub workflow or docs, the registry can become stale.

**Fix**:
1. Run `bash bootstrap/generate-system-registry.sh . --write` as the repo owner.
2. Re-run `bash bootstrap/check-system-awareness.sh .` — expect `system_awareness_ok`.
3. Re-run `bash bootstrap/validate-system.sh . --strict` — expect `system_ok`.
4. If you intentionally keep files outside AIAST management, do not leave them under
   `.github/` without a maintainer decision; relocate or document an exception with
   product owner approval.

## Integrity manifest mismatch

**Symptom**: `verify-integrity.sh --check` reports hash mismatches.

**Fix**:
1. If you intentionally modified system files, regenerate: `bootstrap/verify-integrity.sh --generate --target .`
2. If unexpected: run `bootstrap/detect-drift.sh .` to understand what changed.
3. Use `bootstrap/system-doctor.sh . --heal` for safe recovery.

## System-doctor reports drift

**Symptom**: `detect-drift.sh` reports version or structural drift.

**Fix**:
1. Compare installed version with source template version.
2. Run `bootstrap/update-template.sh . --source <template> --dry-run` to preview changes.
3. Apply with `bootstrap/update-template.sh . --source <template> --strict`.

## Bootstrap script not found or not executable

**Symptom**: `bash: bootstrap/validate-system.sh: No such file or directory`

**Fix**:
1. Check you are running from the repo root.
2. Run `chmod +x bootstrap/*.sh` to fix permissions.
3. If files are missing, run `bootstrap/install-missing-files.sh .`.

## How to get more help

1. Run `bootstrap/system-doctor.sh . --report` for a full diagnostic.
2. Check `_system/DEBUG_REPAIR_PLAYBOOK.md` for structured debugging.
3. Check `_system/FAILURE_MODES_AND_RECOVERY.md` for recovery paths.
