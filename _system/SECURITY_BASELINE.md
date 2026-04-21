# Security Baseline (App-Specific Placeholder)

This file is a scaffold placeholder for app-specific security baseline policy.

In the master template, keep this neutral. In each copied app repo, replace with
product-specific data classification, controls, and compliance requirements.

## Status

- [ ] Replaced with app-specific security baseline

## Data classification model (fill)

| Level | Example data | Handling requirements |
|---|---|---|
| Restricted |  |  |
| Confidential |  |  |
| Internal |  |  |
| Public |  |  |

## Authentication and session policy (fill)

- Identity provider(s):
- Session model:
- Session timeout:
- MFA policy:
- Secret and token storage policy:

## Authorization policy (fill)

- Role model:
- Resource ownership model:
- Sensitive action controls:
- Audit logging requirements:

## Input and content security (fill)

- Input validation approach:
- Upload handling/quarantine policy:
- MIME/content verification requirements:
- Anti-abuse and rate limiting approach:

## AI boundary policy (optional, fill if AI is used)

- Redaction requirements before provider calls:
- Allowed providers:
- Prompt injection mitigations:
- AI artifact audit requirements:

## Logging and observability security (fill)

- PII redaction policy:
- Security event audit trail policy:
- Correlation ID requirements:
- Retention and access controls:

## Infrastructure baseline (fill)

- Transport security requirements:
- Runtime/container hardening requirements:
- Secrets management requirements:
- Network boundary requirements:

## Validation

After replacing placeholders in a real repo, align with:

- `_system/SECURITY_HARDENING_CONTRACT.md`
- `_system/THREAT_MODEL_TEMPLATE.md`
- `_system/SECURITY_REDACTION_AND_AUDIT.md`
