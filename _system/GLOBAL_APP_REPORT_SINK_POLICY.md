# Global App Report Sink Policy

`bootstrap/append-global-app-report.sh` discovery order:

1. `AIAST_GLOBAL_APP_REPORT` env var
2. `registry/global_report_sink.yaml`
3. explicit `--sink` flag

Outside-repo append behavior is dry-run by default and requires explicit
`--approve-external-write` to perform append.
