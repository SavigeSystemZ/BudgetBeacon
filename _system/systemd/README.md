# systemd Scaffolds

Use `bootstrap/generate-systemd-unit.sh` to emit hardened units for an installed repo.

## Presets

- `http` — long-running HTTP or API process
- `worker` — background worker or queue consumer
- `timer` — scheduled task with `.service` and `.timer`

## Example

```bash
bootstrap/generate-systemd-unit.sh \
  --preset http \
  --service-name myapp-api \
  --exec-start "/usr/lib/myapp/venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000" \
  --working-directory /usr/lib/myapp \
  --user myapp \
  --group myapp \
  --environment-file /etc/myapp/env \
  --output-dir ./ops/systemd
```

Review the generated units before installation and adjust capability or filesystem restrictions only when required by the app.

Use `systemd-analyze verify <unit-files...>` against generated units during packaging or release smoke whenever the host environment provides it.
