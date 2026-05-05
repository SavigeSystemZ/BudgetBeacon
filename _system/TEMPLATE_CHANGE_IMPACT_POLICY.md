# Template Change Impact Policy

AIAST template changes are governance changes. Treat them with the same rigor
as code that can reshape many downstream repos.

## Change classes

### High risk

- precedence, load-order, or authority-chain changes
- host prompt, host bundle, or adapter generation changes
- install, upgrade, repair, heal, or drift-management changes
- awareness, registry, integrity, or hallucination-defense changes
- changes that could overwrite repo-owned context or working files in installed
  repos
- new installable `_system/` contracts that become part of normal startup

### Medium risk

- prompt-pack, prompt-template, role-catalog, or hook-index changes
- new validators or stricter validation rules
- packaging, install, distribution, or runtime-foundation scaffolding changes
- new golden-example patterns or updated neutral examples

### Lower risk

- clarifying docs that do not change authority or validation behavior
- release notes and changelog alignment
- purely additive factory-only reporting with no installable impact

## Required follow-through

High-risk changes require:

- companion updates to the affected canonical docs and machine-readable mirrors
- impact review via factory tooling
- instruction-layer validation
- awareness and integrity validation
- migration-safety review if installed repos could be affected

Medium-risk changes require:

- the relevant validator or smoke path
- cross-reference updates where discovery would otherwise drift
- honest release-note or handoff updates

Lower-risk changes still require:

- truthful cross-links
- no duplicate authority surfaces

## Migration safety rule

When a template change touches install, upgrade, repair, or managed-file refresh
behavior:

- preserve repo-owned application truth
- preserve repo-owned working files
- preserve `_system/context/` state unless the repo explicitly requests a reset
- never replace user-authored app context with template defaults silently

If preservation requires staging repo-owned context before a managed refresh,
stage it deterministically and restore it explicitly.

## Related checks

- `bootstrap/validate-instruction-layer.sh`
- `bootstrap/detect-instruction-conflicts.sh`
- `bootstrap/check-system-awareness.sh`
- `bootstrap/system-doctor.sh`

## Downstream preservation and sync notices

Install/update flows that touch application repos must honor
`DOWNSTREAM_PRESERVATION_AND_SYNC_NOTICE_POLICY.md` and emit
`_system/TEMPLATE_SYNC_NOTICE.md` when writes succeed so the next agent session
runs a documented health gate.
