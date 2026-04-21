# Backend Rollback

Use these steps for backend-networking or env regressions:

1. Revert the compose/env/doc changes together so endpoint config and docs stay aligned.
2. If a host port was introduced, remove the host publish first and fall back to the previous internal-only path.
3. Restore the previous values in `registry/ports.yaml` and `registry/backend-assignments.yaml`.
4. Re-run `bash tools/security-preflight.sh` and `bash bootstrap/check-environment.sh "$(pwd)"` to confirm the rollback matches policy.

Do not delete backend volumes or invalidate live queue/session data during rollback unless the change explicitly required destructive approval.
