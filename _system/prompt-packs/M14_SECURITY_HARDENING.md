# M14 Security Hardening Pack

This prompt pack focuses on hardening and securing an application according to the `_system/SECURITY_HARDENING_CONTRACT.md`.

Before using this pack, load `AGENTS.md`, `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`, `_system/REPO_OPERATING_PROFILE.md`, and `_system/LOAD_ORDER.md` first. Treat this pack as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

## Goal
- Apply loopback-only binding.
- Implement systemd hardening.
- Configure secure web headers (CSP, CORS, etc.).
- Ensure structured, redacted logging.
- Prevent SSRF and privilege escalation.
- Keep Redis, Postgres, Dragonfly, MinIO, queues, and similar internals off host-published ports by default.

## Task Sequence

### 1. Network & Lifecycle Hardening
- [ ] Inspect the application entry point (e.g., `server.js`, `main.py`).
- [ ] Force the host to `127.0.0.1` or `::1`.
- [ ] Require explicit bind flags for fallback servers such as `python3 -m http.server`.
- [ ] Verify internal backends use Docker-internal networking by default and justify any retained host publishing.
- [ ] Create/Update the systemd unit with hardening flags (UMask, NoNewPrivileges, PrivateTmp, etc.).
- [ ] Ensure `dev` and `prod` start commands are distinct.

### 2. Web Security Layer
- [ ] Add middleware for security headers (e.g., `helmet` for Express, `FastAPI.middleware.cors` for Python).
- [ ] Configure a strict `Content-Security-Policy`.
- [ ] Ensure `HttpOnly` and `SameSite` flags are on all cookies.
- [ ] Implement `Cache-Control: no-store` for authenticated routes.

### 3. Logging & Error Handling
- [ ] Switch logging to a structured JSON format (e.g., `winston`, `pino`, `structlog`).
- [ ] Implement a redaction filter for passwords, tokens, and sensitive headers.
- [ ] Disable verbose stack traces in the production response path.

### 4. SSRF & Privilege Checks
- [ ] Identify features that fetch remote URLs.
- [ ] Add IP/Domain validation to block loopback and private ranges.
- [ ] Add a runtime check to ensure the UI process is not running as root.

### 5. Validation
- [ ] Run `tools/security-preflight.sh`.
- [ ] Run `bootstrap/check-network-bindings.sh <repo> --include-template-assets`.
- [ ] Run `bootstrap/check-environment.sh <repo>`.
- [ ] Verify that the `readiness` endpoint is operational.
- [ ] Perform a full `_system/review-playbooks/SECURITY_HARDENING_REVIEW_PLAYBOOK.md` audit.
