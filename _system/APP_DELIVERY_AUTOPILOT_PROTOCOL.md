# App Delivery Autopilot Protocol

`bootstrap/run-app-delivery-autopilot.sh` orchestrates delivery readiness checks
in deterministic order:

1. repo root and mode checks
2. fleet readiness
3. permission drift check
4. safe in-repo repair
5. validation command discovery
6. validation autopilot run
7. installer/setup maturity checks
8. runtime foundation checks
9. port/network checks
10. context freshness checks
11. quality scoring
12. status report emission
13. handoff evidence write

Outside-repo writes must remain dry-run unless explicit approval flags are used.
