# Memory

Store stable project memory here.

## Good entries

- persistent architecture conventions
- stable operator preferences
- naming or UX conventions worth preserving
- long-lived constraints that future agents should not rediscover
- recurring validation or release habits worth preserving

## Entries

- Convention: after changing canonical instruction surfaces or managed write flows, refresh `_system/SYSTEM_REGISTRY.json`, `_system/REPO_OPERATING_PROFILE.md`, `_system/repo-operating-profile.json`, and `_system/INTEGRITY_MANIFEST.sha256`
  Why preserve it: these are trust surfaces and drift is easy to introduce if regeneration is skipped

- Convention: use normal validation on the neutral source template and reserve strict validation for installed repos unless placeholder semantics are changed deliberately
  Why preserve it: the source template intentionally retains blank project-profile identity fields

- Convention: run `bootstrap/detect-instruction-conflicts.sh --strict` whenever adapter, prompt-pack, or precedence files change
  Why preserve it: multi-layer instruction drift is easier to detect mechanically than to reason about after the fact

- Convention: leave overnight handoff in repo files, not only in chat history
  Why preserve it: the next agent should be able to resume from `WHERE_LEFT_OFF.md`, `TODO.md`, and `_system/context/` without thread-specific context
