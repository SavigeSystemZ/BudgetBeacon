# Threat Model Template

Use this template when the project gains network exposure, sensitive data, privileged helpers, or multi-tenant behavior.

## System summary

- Service or component:
- Main user flows:
- Sensitive assets:
- Trust boundaries:

## Threat actors

- External attacker:
- Authenticated but malicious user:
- Internal operator misuse:
- Supply-chain or dependency compromise:

## Attack surfaces

- Public HTTP or gRPC endpoints:
- Background jobs or schedulers:
- File upload or import paths:
- External fetch or callback features:
- Admin or support surfaces:

## High-risk scenarios

- Injection or unsafe deserialization:
- SSRF or internal network abuse:
- Auth or session bypass:
- Sensitive data exposure:
- Privilege escalation:

## Mitigations

- Preventive controls:
- Detection controls:
- Recovery or rollback controls:
- Evidence or audit surfaces:

## Residual risk

- Accepted risks:
- Follow-up work:
