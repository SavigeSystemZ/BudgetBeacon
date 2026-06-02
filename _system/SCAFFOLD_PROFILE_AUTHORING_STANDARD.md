# Scaffold Profile Authoring Standard

Use this standard when adding or updating entries in
`_system/SCAFFOLD_PROFILE_MATRIX.md` and
`_system/runtime-profiles/scaffold-profiles.json`.

## Required Fields Per Profile

- `id`
- included surfaces
- excluded surfaces
- required docs
- required validators
- default guardrails
- installer expectations
- port/network expectations
- runtime foundation expectations
- platform expectations (mobile/desktop/web where relevant)
- security/privacy baseline
- fleet compatibility
- downstream mutability model
- quality score target

## Authoring Rules

- Keep profile IDs stable and lowercase.
- Use additive evolution; avoid destructive renames unless migration scripts
  are provided.
- Mark maintainer-only profiles explicitly (`maintainer_only: true`).
- Non-meta profiles must exclude MOS-maintainer-only surfaces.
- Validate profile IDs against matrix references and manifest entries.

## Validation Expectations

- `bootstrap/validate-scaffold-profile.sh` validates a single profile id.
- `bootstrap/validate-scaffold-profiles.sh` validates full profile contract
  coverage and schema alignment.
