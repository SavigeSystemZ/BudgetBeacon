# Migration Guide

How to migrate from other setups to AIAST.

## From no agent system

If your repo has no agent governance files:

1. Run `bootstrap/init-project.sh /path/to/your/repo --app-name "YourApp"`.
2. Fill `_system/PROJECT_PROFILE.md` with your stack details.
3. Run `bootstrap/recommend-starter-blueprint.sh .` and apply the result.
4. Run `bootstrap/validate-system.sh . --strict`.
5. Commit the new `_system/` directory and adapter files.

Your existing code is untouched. AIAST adds governance alongside it.

## From a custom CLAUDE.md

If your repo already has a `CLAUDE.md` with custom instructions:

1. Back up your existing `CLAUDE.md`.
2. Run `bootstrap/init-project.sh /path/to/your/repo --app-name "YourApp"`.
   - The installer preserves your existing README.md (installs as AI_SYSTEM_README.md if needed).
   - Your existing CLAUDE.md will be overwritten with the generated adapter.
3. Move your custom instructions into `_system/PROJECT_RULES.md` or `_system/PROJECT_PROFILE.md`.
4. The generated CLAUDE.md loads AGENTS.md, which loads your rules. Your custom rules now apply to ALL agents, not just Claude.

## From Cursor-only setup

If your repo uses `.cursorrules` and `.cursor/` but no shared governance:

1. Back up your `.cursorrules` and `.cursor/` directory.
2. Run `bootstrap/init-project.sh /path/to/your/repo --app-name "YourApp"`.
3. Move your custom Cursor rules into `_system/PROJECT_RULES.md`.
4. Move Cursor-specific workflows into `.cursor/commands/` or `.cursor/skills/`.
5. The generated `.cursorrules` loads `AGENTS.md`, which loads your project rules.

## From another agent framework

If your repo uses a different agent governance system:

1. Identify which files carry your governance rules.
2. Run `bootstrap/init-project.sh /path/to/your/repo --app-name "YourApp"`.
3. Map your existing rules into AIAST equivalents:

| Your file | AIAST equivalent |
|-----------|-----------------|
| Agent instructions | `_system/PROJECT_RULES.md` |
| Context/memory | `_system/context/*.md` |
| Validation rules | `_system/VALIDATION_GATES.md` |
| Code standards | `_system/CODING_STANDARDS.md` |
| Security rules | `_system/SECURITY_REDACTION_AND_AUDIT.md` |
| Working state | `TODO.md`, `PLAN.md`, `WHERE_LEFT_OFF.md` |

4. Remove the old framework files once AIAST is validated.
5. Run `bootstrap/validate-system.sh . --strict`.

## After migration

- Run `bootstrap/system-doctor.sh .` to verify everything is healthy.
- Run `bootstrap/check-working-directory-alignment.sh .` and `bootstrap/check-project-target-consistency.sh .` before large writes.
- Use `bootstrap/emit-session-environment.sh .` to capture authority mode and scope context.
- Fill `_system/PROJECT_PROFILE.md` — this is the most important step.
- Set up your validation commands in the profile.
- All agents will now share the same rules and handoff protocol.

## Optional global compatibility redirects

If your host workflow needs parent/global compatibility entrypoints, install thin redirect shims:

- `bootstrap/install-root-redirect-shims.sh --target-repo .`
- `bootstrap/install-tool-global-redirects.sh --target-repo .`

Use `bootstrap/check-global-shim-alignment.sh` to ensure redirects stay non-authoritative.

## What AIAST does NOT touch

- Your application source code
- Your build configuration
- Your CI/CD pipelines (unless you use the ci-integration plugin)
- Your package manager files
- Your test files

AIAST is purely additive governance. It sits alongside your code without modifying it.
