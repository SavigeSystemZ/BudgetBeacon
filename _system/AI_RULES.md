# AI Rules (App-Specific Placeholder)

This file is a scaffold placeholder for app-specific AI usage policy.

In the master template, keep this file neutral. In a real app repo, replace
placeholder sections with product-specific truth and approved policy.

## Status

- [ ] Replaced with app-specific AI governance

## Purpose

Define what AI is allowed to do, forbidden to do, and required controls for this
specific product domain.

## Allowed AI actions (fill for your app)

- Placeholder: summarize user-provided content with provenance
- Placeholder: extract structured fields with confidence metadata
- Placeholder: draft output artifacts for user review only

## Forbidden AI actions (fill for your app)

- Placeholder: invent facts, evidence, or events
- Placeholder: perform irreversible actions without explicit authorization
- Placeholder: auto-submit external operations without user approval

## Required controls (fill for your app)

- Provenance and traceability requirements:
- Confidence scoring requirements:
- Contradiction detection requirements:
- User confirmation workflow requirements:
- Redaction and privacy controls:
- Audit trail requirements:

## Provider abstraction contract (optional)

If your app uses LLM providers, define adapters in product code so business logic
does not depend on a single provider implementation.

## Validation

When this file is customized in a real repo:

1. cross-check with `_system/SECURITY_BASELINE.md`
2. cross-check with `_system/PROJECT_PROFILE.md`
3. run `bootstrap/validate-system.sh . --strict`
