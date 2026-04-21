# Chatbot Intents

Use these intents as the starting point for your project-owned action registry.

## Core intents

- `search_data` — search local records or remote indexed data
- `create_record` — create a new entity after confirmation
- `run_report` — generate a report and persist an audit event
- `export_report` — export CSV, JSON, or PDF output
- `open_help` — answer from local documentation first
- `handoff_to_human` — escalate when the request requires support or privileged review

## Action bus contract

- Every intent maps to an application-owned function or command bus action.
- Every state-changing action must check permission before execution.
- Every privileged action must emit an audit log entry with actor, action, and outcome.

## Example prompt

`Export the latest revenue report to CSV and email it to finance.`

Expected orchestration:

1. resolve the report target
2. confirm export permission
3. invoke the export action
4. invoke the notification action
5. record the audit trail
