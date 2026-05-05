# Project Identity And Scope Protocol

This protocol prevents unintended writes by checking that requested target identity matches the active working directory and repo identity.

## Identity sources

- Working directory basename
- Git remote repo slug
- `_system/PROJECT_PROFILE.md` identity fields
- Optional requested target from task metadata or operator input

## Required checks

1. Resolve actual repo root.
2. Confirm whether root is under `~/.MyAppZ`.
3. Compare requested target (if provided) with repo basename.
4. Compare git remote name with repo basename.
5. Compare project profile app identity with repo basename.

## Mismatch policy

- If mismatch is high-risk (cross-project or wrong repo target), fail closed and block writes.
- If mismatch is informational (missing profile field), emit warning and continue read-only planning.
- Before any cross-project action, require explicit operator confirmation.

## Script interface expectations

- `bootstrap/check-working-directory-alignment.sh`
  - emits `alignment_ok|alignment_warn|alignment_fail`
- `bootstrap/check-project-target-consistency.sh`
  - emits `target_consistency_ok|target_consistency_warn|target_consistency_fail`

## Integration points

- Startup preflight for adapters and tool overlays.
- `bootstrap/init-project.sh` preflight when global or snapshot flags are enabled.
- `bootstrap/system-doctor.sh` for ongoing health checks.

## Instruction domain (wrong-app prompts)

Path and remote checks above do **not** detect when a human pastes a prompt meant for a **different product** into this repo. For that class of mistake, load and follow `_system/INSTRUCTION_DOMAIN_ALIGNMENT_PROTOCOL.md` and keep `_system/PROJECT_DOMAIN_MANIFEST.json` accurate for the product you are actually building.
