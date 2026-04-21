# Security, Redaction, And Audit

Use this document to keep the operating system safe by default.

## Security baseline

- Validate inputs at boundaries.
- Preserve authorization seams.
- Never commit secrets.
- Never leak sensitive values into prompts, logs, exports, or reports.
- Use HTTPS everywhere. Reject plain HTTP.
- Apply least privilege to all access patterns.

## OWASP Top 10 awareness

Every agent must actively guard against these risks when writing or reviewing code:

1. **Injection** (SQL, NoSQL, OS command, LDAP): Use parameterized queries. Never concatenate user input into queries or commands. Use ORM methods or prepared statements.
2. **Broken authentication**: Hash passwords with bcrypt, scrypt, or argon2. Enforce strong password policies. Implement account lockout. Use secure session management. Invalidate sessions on logout.
3. **Sensitive data exposure**: Encrypt data at rest and in transit. Never log sensitive fields (passwords, tokens, PII). Mask sensitive data in UI. Use appropriate cache-control headers.
4. **XML external entities (XXE)**: Disable external entity processing in XML parsers. Prefer JSON over XML.
5. **Broken access control**: Verify authorization on every request, not just the UI layer. Deny by default. Validate object ownership before returning data.
6. **Security misconfiguration**: Remove default credentials. Disable debug output in production. Set secure HTTP headers. Keep dependencies updated.
7. **Cross-site scripting (XSS)**: Escape output by context (HTML, JavaScript, URL, CSS). Use Content Security Policy headers. Use framework auto-escaping. Never use `dangerouslySetInnerHTML` or `v-html` with user data.
8. **Insecure deserialization**: Validate and sanitize serialized data. Use safe serialization formats. Never deserialize untrusted data directly into objects.
9. **Using components with known vulnerabilities**: Run dependency audits in CI. Update vulnerable packages promptly. Monitor advisories.
10. **Insufficient logging and monitoring**: Log authentication attempts, access control failures, input validation failures, and application errors. Include request IDs for tracing. Never log sensitive data.

## HTTP security headers

Set these headers on all responses:

- `Strict-Transport-Security: max-age=31536000; includeSubDomains` — enforce HTTPS.
- `X-Content-Type-Options: nosniff` — prevent MIME sniffing.
- `X-Frame-Options: DENY` or `SAMEORIGIN` — prevent clickjacking.
- `Content-Security-Policy` — restrict script, style, and resource sources. Start strict and loosen as needed.
- `Referrer-Policy: strict-origin-when-cross-origin` — control referrer information.
- `Permissions-Policy` — disable unused browser features (camera, microphone, geolocation).
- Remove `X-Powered-By` and `Server` headers that expose technology stack.

## Input validation patterns

- Validate type, length, format, and range on all external input.
- Reject unexpected fields. Use allowlists, not denylists.
- Sanitize before storage. Escape before rendering.
- Validate on the server even when client validation exists.
- Use schema validation libraries (zod, pydantic, joi) for complex input shapes.
- Rate limit all public endpoints. Apply stricter limits to authentication and sensitive operations.

## Secret management

- Use environment variables or secret managers for credentials. Never hardcode.
- Use `.env.example` with placeholder values. Never commit `.env` files.
- Rotate secrets on a schedule and after any suspected exposure.
- Use different credentials for development, staging, and production.
- Audit code for accidentally committed secrets. Use tools like git-secrets or gitleaks in CI.

## Redaction pipeline

1. Normalize text before inspection.
2. Hard-fail on high-confidence secrets such as private keys, access tokens, and embedded credentials.
3. Warn or redact medium-confidence secrets such as high-entropy strings and tokens inside URLs.
4. Allow placeholders such as `YOUR_KEY_HERE`.
5. Emit a redaction report when the project requires export or audit evidence.

## Audit baseline

Record security-relevant events when the project warrants it:

- Privileged actions.
- Scope elevation.
- Authentication successes and failures.
- Access control violations.
- Export or packaging of sensitive artifacts.
- Diff or merge operations that change generated artifacts or prompt packs.
- Dependency updates that affect security posture.

## Validation

- Add unit tests for new redaction rules when they exist in code.
- Add regression tests for any sanitized incident patterns.
- Run SAST (static application security testing) tools in CI where available.
- Run dependency vulnerability scans on every build.
- Test authentication and authorization boundaries with explicit pass/fail cases.
