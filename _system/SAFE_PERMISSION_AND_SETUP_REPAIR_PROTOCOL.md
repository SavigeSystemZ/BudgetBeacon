# Safe Permission and Setup Repair Protocol

`bootstrap/repair-safe-permission-drift.sh` only auto-fixes bounded, in-repo,
low-risk issues.

## Allowed Auto-Repairs

- missing user write bit on current-user-owned files within active repo
- missing executable bits on managed bootstrap scripts
- additive restoration of missing managed directories

## Forbidden Without Explicit Approval

- ownership changes (`chown`, `sudo`)
- writes outside active repo
- sibling repo mutations
- system/user global config paths
- secrets, env files, databases, unknown file deletion
