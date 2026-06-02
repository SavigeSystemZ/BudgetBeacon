# Project-Specific Placeholder File Standard

Use this standard when shipping app-facing placeholders from the parent template.

## Header Template

```
# <File Name>
Status: TEMPLATE PLACEHOLDER — fill after scaffold.
This file is intentionally app-neutral in the parent AIAST template.
After scaffold into a project-specific repo, replace this section with project-specific truth.
Do not copy facts from other apps.
Do not leave this file blank after the first meaningful project setup pass.
Do not write secrets here.
```

## Required Placeholder Classes

- product brief
- domain manifest
- architecture invariants
- integration surfaces
- security baseline
- AI rules
- validation profile
- installer profile
- port profile
- archetype selection memo
- quality score history
- fleet status history
- external report config
- app-specific context files (see `APP_CONTEXT_FILE_MATRIX.md`)

## Enforcement Rules

- Parent template must remain neutral and reusable.
- Placeholders must not include downstream app facts.
- First project-local onboarding pass must replace placeholder prose with real
  repo truth.
