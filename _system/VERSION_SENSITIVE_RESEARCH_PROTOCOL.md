# Version-Sensitive Research Protocol

Use repo-local facts first. Use external research only when compatibility,
syntax, platform behavior, package behavior, or current vendor/framework details
are genuinely uncertain.

## Typical triggers

- framework or package upgrades
- platform-specific install or packaging work
- external API behavior that may have changed
- host-tool or adapter behavior that depends on current versions
- build, runtime, or distribution tooling with version-specific syntax

## Rules

- Prefer primary sources when researching technical behavior.
- Record the source, version, date, and uncertainty when research changes a
  reusable decision.
- Keep project-specific findings in repo-owned notes, docs, or handoff files,
  not in canonical installable template doctrine by default.
- Promote durable findings into AIAST only through maintainer review and the
  promotion gate.
- Do not paste secrets, private config, or sensitive repo data into research
  queries.

## Promotion rule

Transient findings stay local until they become a stable, reusable governance
pattern. Only the reusable pattern belongs in `TEMPLATE/`.

## Related surfaces

- `_system/READ_BUNDLES.md`
- `_system/PROMPT_EMISSION_CONTRACT.md`
- `_system/HOOK_AND_ORCHESTRATION_INDEX.md`
- `_system/TEMPLATE_CHANGE_IMPACT_POLICY.md`
