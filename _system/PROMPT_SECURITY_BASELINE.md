# Security Baseline Prompt Rules

- Do not publish internal backends to the host by default.
- Prefer Docker-internal networking and `expose:` over `ports:`.
- If host publishing is required, bind to loopback only and document the justification.
- Never commit real credentials; scaffold placeholders only.
- Require healthchecks, restart policies, and an explicit persistence decision for internal backends.
- Run `tools/security-preflight.sh` before considering the work complete.
