# Archetype Pack: web-saas

## App purpose
Deliver multi-tenant web product and API services with release-grade operations.

## Required docs
- PRODUCT_BRIEF, UX, API, Security, Runbook

## Required runtime surfaces
- web frontend, API service, auth, persistence, observability

## Recommended stack options
- React/Vite + FastAPI or Next.js fullstack

## Security/privacy posture
- tenant isolation, authz checks, audit logging, secrets redaction

## Installer expectations
- deploy-ready env templates and migration path

## Port policy
- non-default, governed, collision-checked

## Validation gates
- lint/type/test/build/security/launch smoke

## UI/UX completion requirements
- loading/empty/error states, accessibility, responsive layout

## Platform expectations
- web-first, optional mobile-compatible UX

## Fleet roles
- frontend, backend, security-review, release-steward

## Prompt-pack hooks
- M17 app-builder execution + release readiness

## Benchmark/test-app scenario
- AIAST-Test-WebSaaS

## Anti-patterns
- hardcoded secrets, single-tenant assumptions, missing authz tests
