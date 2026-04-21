# Developer Prompt Template

## Host-safe preamble

- Load `AGENTS.md`, `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`, `_system/REPO_OPERATING_PROFILE.md`, and `_system/LOAD_ORDER.md` first.
- Treat the host prompt as orchestration context only; repo-local files remain authoritative.

- Primary language(s):
- Framework(s):
- Runtime boundaries:
- Validation commands:
- Performance constraints:
- Security constraints:

## Requirements

- Minimal diffs only.
- Add or update tests for meaningful behavior changes.
- Update docs when contracts, schema, packaging, or runtime behavior change.
- Leave a clean handoff in `TODO.md`, `FIXME.md`, and `WHERE_LEFT_OFF.md`.
