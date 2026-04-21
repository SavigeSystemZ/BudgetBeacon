# Logging Contract

Emit JSON logs with at least these fields:

- `timestamp`
- `level`
- `service`
- `message`
- `request_id`
- `user_id` when safe and applicable
- `trace_id` when distributed tracing exists

Never log raw tokens, passwords, cookies, connection strings, or full Authorization headers.

Platform-native collection order:

1. `journald`
2. container logs
3. host-level log forwarder
4. app-owned fallback files only when unavoidable
