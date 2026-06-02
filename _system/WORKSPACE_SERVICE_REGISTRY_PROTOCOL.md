# Workspace Service Registry Protocol

Repo-local port registry remains authoritative for each app. An optional
workspace ledger may be used to reduce sibling collision risk.

Default optional ledger path:
`~/.MyAppZ/_AIAST_SHARED/workspace-service-registry.yaml`

Outside-repo writes must default to dry-run unless explicit apply flags are set.
