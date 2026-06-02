# App Archetype Pack Authoring Standard

Every archetype pack in `_system/archetypes/` must define the following
sections:

- app purpose
- required docs
- required runtime surfaces
- recommended stack options
- security/privacy posture
- installer expectations
- port policy
- validation gates
- UI/UX completion requirements
- platform expectations (mobile/desktop/web as relevant)
- fleet roles
- prompt-pack hooks
- benchmark/test-app scenario
- anti-patterns

## Authoring Rules

- Use stable lowercase IDs and filename parity.
- Keep content repo-neutral and reusable across downstream apps.
- Avoid project-specific credentials, vendors, or deployment secrets.
- Include explicit safety boundaries for intrusive/security-sensitive domains.
- Keep benchmark scenarios measurable and machine-checkable where possible.
- Each archetype pack has a companion app-specific context set defined in
  `_system/APP_CONTEXT_FILE_MATRIX.md`; keep the two aligned when sections change.
