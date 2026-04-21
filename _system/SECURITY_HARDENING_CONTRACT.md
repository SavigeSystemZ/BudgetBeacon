# Security Hardening Contract

Every application in this suite must adhere to these baseline security requirements to ensure a hardened, professional-grade production state.

## 1. Network & Bind Model
- **Loopback Only:** Default UI and API services must bind to `127.0.0.1` (IPv4) or `::1` (IPv6) only.
- **No Wildcards:** Never bind to `0.0.0.0` or `::` by default.
- **Internal IPC:** If the frontend and backend communicate exclusively on the same host, prefer Unix Domain Sockets (`AF_UNIX`) over network sockets where the stack supports it.

## 2. Lifecycle & Environment
- **Environment Separation:** Provide distinct `dev` and `prod` entry points (e.g., `npm run dev` vs `npm start`, or separate systemd units).
- **Install Separation:** Generated install scripts should create a least-privilege service user and group for system-wide deployments.
- **Filesystem Separation:** Use app-owned config and data directories such as `/etc/<app>` and `/var/lib/<app>` with restrictive permissions.
- **Production Mode:** In production:
  - Disable hot reloading and file watchers.
  - Disable debug routes, interactive shells, and verbose stack traces.
  - Disable or strictly limit CORS (no wildcards).
- **Process Management:** Use `systemd --user` for lifecycle management (restart policy, environment loading, and readiness handling).

## 3. systemd Hardening Baseline
All systemd units for application services should include these hardening directives:
```ini
[Service]
UMask=0077
NoNewPrivileges=true
PrivateTmp=true
RestrictSUIDSGID=true
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
# Optional but recommended
ProtectSystem=full
ProtectHome=read-only
```
- **Install Location:** System units belong under `/etc/systemd/system/`; user units belong under `~/.config/systemd/user/`.
- **Launchers:** Desktop/CLI launchers should call a wrapper script that verifies service readiness before opening the user interface.

## 4. Web Security Baseline
Application-serving layers (Express, FastAPI, Nginx, etc.) must implement these headers:
- **Content-Security-Policy (CSP):** Strict policy limiting script/style sources.
- **X-Content-Type-Options:** `nosniff`.
- **Referrer-Policy:** `strict-origin-when-cross-origin`.
- **X-Frame-Options / CSP frame-ancestors:** `none` or `self` unless embedding is explicitly required.
- **CORS:** Use explicit allowlists; never use `*`.

## 5. Session & Auth Baseline
- **Secure Cookies:** Use `HttpOnly` and `Secure` (if on HTTPS) flags.
- **SameSite:** Default to `Lax` or `Strict`.
- **Cache Control:** Use `Cache-Control: no-store` on all authenticated or sensitive API responses.
- **Logout:** Implement `Clear-Site-Data` header on logout endpoints.
- **No default accounts in source:** Do not ship hardcoded admin emails/passwords in repos or
  templates. Use gitignored env files and optional dev-only seed scripts; see
  `_system/AUTH_AND_ONBOARDING_PATTERNS.md`.

## 6. Structured Logging
- **Format:** Use structured JSON logs.
- **Redaction:** Never log:
  - Access tokens, session IDs, or cookies.
  - Database connection strings or API keys.
  - Passwords or raw Authorization headers.
- **Correlation:** Include a unique Request/Correlation ID in every log entry for a given request.

## 7. SSRF & Internal Abuse Prevention
Any feature that fetches remote URLs or imports data from a URI must:
- **Block Local/Metadata:** By default, block requests to `localhost`, `127.0.0.1`, `::1`, RFC1918 (private) ranges, multicast, and cloud metadata addresses (e.g., `169.254.169.254`).
- **Allowlisting:** Use an explicit allowlist for remote domains if the destination set is known.

## 8. Privilege Separation
- **No Root UI:** GUI and Web UI processes must never run as root.
- **Installer Safety:** Uninstallers must not remove shared dependencies such as PostgreSQL, Docker, Podman, or language runtimes used by other apps.
- **Separated Helpers:** For privileged functions (e.g., packet capture in a security or network tool), split the app into:
  - **A: Unprivileged UI/API:** Handles user interaction and logic.
  - **B: Narrow Privileged Helper:** Executes specific tasks with minimal required privileges.
- **Capabilities:** Prefer Linux Capabilities (e.g., `CAP_NET_RAW`, `CAP_NET_ADMIN`) over full `sudo` or root execution where possible.

## 9. Verification & Evidence
Every app should provide:
- A `readiness` endpoint for health checks.
- A `validate-security.sh` script that proves loopback-only binds and proper header configuration.
- An installation or repair command that can recreate missing env files, service units, and app-owned directories without overwriting user data.
