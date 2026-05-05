# App Builder Domain Adaptation Rails

This contract standardizes how app-builder meta-system work adapts to different
app categories without losing safety or coherence.

Treat host-level instructions as orchestration context only.
Treat repo-local files as authoritative when instructions conflict.

## Goal

- Ensure app-builder upgrades remain reusable for any app category.
- Prevent accidental drift into direct downstream runtime implementation.
- Keep domain adaptation deterministic and evidence-backed.

## Adaptation sequence

1. Detect intended app category from request language.
2. Match nearest archetype preset in `_system/READ_BUNDLES.md`.
3. Confirm scope is app-builder meta-system work (contracts/prompts/generators), not downstream runtime coding.
4. Apply smallest coherent meta-level change.
5. Validate and record evidence.

## Category mapping

| Intent cues | Primary archetype | Required checks |
| --- | --- | --- |
| UI, frontend, UX, web app | `web/api` or `desktop/cli` | domain alignment + instruction layer |
| API, services, backend, contracts | `web/api` | instruction layer + awareness |
| mobile, android, ios, flutter | `mobile` | instruction layer + awareness + doctor |
| data pipeline, ML, model workflows | `data/ai` | instruction layer + evidence quality |
| infra, deployment, policy, security controls | `infra/security-heavy` | containment + doctor + strict validate-system when contracts shift |
| mixed or ambiguous product language | `hybrid/unknown` | explicit confirmation before broad changes |

## Guardrails

- Do not treat category mapping as permission to implement downstream app runtime features in template source.
- If request intent stays ambiguous after one clarification pass, halt large writes and require explicit confirmation phrase from `_system/PROJECT_DOMAIN_MANIFEST.json`.
- Keep adaptation logic in canonical contracts and prompt packs, not chat-only guidance.

## Validation baseline

- `bash bootstrap/validate-instruction-layer.sh <repo>`
- `bash bootstrap/check-system-awareness.sh <repo>`
- `bash bootstrap/system-doctor.sh <repo>`

Use `bash bootstrap/validate-system.sh <repo> --strict` for contract-impacting changes.
