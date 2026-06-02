# MOS Downstream Exclusion Policy

Ordinary downstream app repos must receive the project-local AIAST operating
layer only. They must not receive AIAST parent-template maintenance layers or
MOS source/product layers through normal app scaffold flows.

## Forbidden In Normal App Scaffolds

- `MOS_TEMPLATE/`
- `MOS_SOURCE_LIBRARY/`
- `_META_AGENT_SYSTEM/`
- `_TEMPLATE_FACTORY/`
- `_MOS_TEMPLATE_FACTORY/`

## Allowed Paths

- App repos may contain project-local `_system/` governance files.
- App repos may contain generated runtime foundations outside `_system/`.
- MOS repos must be created through the MOS bootstrap path, not by widening
  normal AIAST app scaffolds.

## Maintainer Profile Rule

`meta-system-development` may expose maintainer-oriented AIAST contracts inside
the installable `TEMPLATE/_system/` surface, but it still must not copy
parent-repo-only directories into an ordinary downstream app.

## Enforcement

- `bootstrap/check-mos-downstream-exclusion.sh`
- `bootstrap/validate-scaffold-output.sh`
- `bootstrap/check-scaffold-required-files.sh`
- `bootstrap/scaffold-system.sh --profile <name>`
