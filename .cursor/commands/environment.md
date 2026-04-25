Emit and review the current session environment before significant writes:
Run `bash bootstrap/emit-session-environment.sh .` and confirm authority mode, repo identity, and branch/orphan status.

Recommended pre-write flow:

1. `bash bootstrap/check-working-directory-alignment.sh .`
2. `bash bootstrap/check-project-target-consistency.sh .`
3. `bash bootstrap/emit-session-environment.sh .`
4. if mismatches are reported, halt writes and confirm target scope

Optional JSON output for tooling:
- `bash bootstrap/emit-session-environment.sh . --json`
