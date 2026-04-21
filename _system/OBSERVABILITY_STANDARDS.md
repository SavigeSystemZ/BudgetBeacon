# Observability Standards

Use observability surfaces that are easy to automate, easy to review, and safe to expose.

## Logging

- Emit structured logs by default.
- Include request or correlation IDs for request-driven work.
- Keep app output and logs separate for CLI tools.
- Redact secrets, tokens, cookies, connection strings, and raw auth headers.
- Prefer stable fields such as `timestamp`, `level`, `service`, `request_id`, and `trace_id`.

## Metrics

- Expose Prometheus-style metrics where a long-running service exists.
- Use a stable `/health` or readiness endpoint for HTTP services.
- Prefer explicit success, error, latency, queue depth, and resource metrics over vanity counters.

## Tracing and profiling

- Use OpenTelemetry where distributed tracing matters.
- Keep CPU and memory profiling optional and gated behind safe runtime controls.
- Never enable verbose profiling endpoints by default in production.

## Collection and retention

- Prefer platform-native collection first: `journald`, container logs, or host-level agents.
- Document Android `logcat` integration if the project ships a mobile client.
- Document rotation and retention expectations in the project runbook.
- Treat logs and traces as potentially sensitive data.
