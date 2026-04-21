# Backend Validation

Run these after changing compose, env, or backend ownership.

```bash
docker compose -f ops/compose/compose.yml config
bash tools/security-preflight.sh
bash bootstrap/check-network-bindings.sh "$(pwd)" --include-template-assets
bash bootstrap/check-environment.sh "$(pwd)"
```

Expected signals:

- `docker compose ... config` renders cleanly with no schema errors
- `tools/security-preflight.sh` prints `security_preflight_ok`
- backend inventories and registry files exist and describe the current topology
- internal backends stay off host `ports:` unless explicitly justified
