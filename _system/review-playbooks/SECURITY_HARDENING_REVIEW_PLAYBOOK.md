# Security Hardening Review Playbook

Use this playbook to verify that an application meets the `_system/SECURITY_HARDENING_CONTRACT.md`.

## 1. Network & Bind Check
- [ ] Are services binding to `127.0.0.1` (not `0.0.0.0`)?
- [ ] Is loopback enforced in both development and production configuration?
- [ ] If local frontend/backend communication exists, are Unix sockets considered?

## 2. systemd Unit Review
- [ ] Does the service unit use `UMask=0077`?
- [ ] Is `NoNewPrivileges=true` set?
- [ ] Are filesystem hardening flags (`PrivateTmp`, `ProtectSystem`, `ProtectHome`) present?
- [ ] Is `RestrictAddressFamilies` limited to `AF_UNIX AF_INET AF_INET6`?

## 3. Web Layer Security
- [ ] **CSP:** Is a Content Security Policy implemented? Does it avoid `unsafe-inline` where possible?
- [ ] **Headers:** Are `X-Content-Type-Options: nosniff` and `Referrer-Policy` set?
- [ ] **Clickjacking:** Is `frame-ancestors 'none'` or `X-Frame-Options: DENY` active?
- [ ] **CORS:** Are all CORS entries explicit? No wildcards found in the codebase?

## 4. Auth & Session Management
- [ ] Are cookies marked `HttpOnly` and `SameSite=Lax/Strict`?
- [ ] Does the logout endpoint return `Clear-Site-Data`?
- [ ] Is `Cache-Control: no-store` applied to authenticated API responses?

## 5. Logging Integrity
- [ ] Is the logging format JSON-structured?
- [ ] Search the codebase for `logger.log(token)`, `logger.log(password)`, etc. Ensure redaction is in place.
- [ ] Are correlation IDs present in the log output for tracing?

## 6. SSRF Prevention
- [ ] Find all instances of `fetch()`, `requests.get()`, or similar URI-loading functions.
- [ ] Does the logic block `127.0.0.1`, private IP ranges, and cloud metadata IPs (`169.254.169.254`)?

## 7. Privilege Model
- [ ] Does the application check for root/sudo and refuse to run the UI layer as a privileged user?
- [ ] Are privileged operations isolated to a minimal helper script or service?
- [ ] Are specific Linux capabilities utilized instead of full root access?

## 8. Automated Validation
- [ ] Does `validate-security.sh` exist and pass?
- [ ] Does the `readiness` endpoint return a `200 OK` only when internal checks pass?
