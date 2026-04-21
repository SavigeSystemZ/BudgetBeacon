# Plugin Contract

Plugins extend AIAST without modifying core files directly.

## Location

- Store plugin assets under `_system/plugins/<plugin-name>/`.
- Each plugin must include `plugin.json` and `README.md`.
- Optional: `run.sh` for executable plugins.

## Manifest schema (plugin.json)

```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "What this plugin does",
  "aiast_min_version": "1.20.0",
  "hooks": ["security.scan", "validation.report"],
  "capabilities": ["security-scanner", "ci-reporter"],
  "owned_paths": ["_system/plugins/plugin-name/"],
  "requires": [],
  "enabled": true
}
```

Required fields: `name`, `version`, `description`, `hooks`.
Optional fields: `aiast_min_version`, `capabilities`, `owned_paths`, `requires`, `enabled`.

## Allowed hook points

### Bootstrap hooks
- `bootstrap.pre_flight` — runs before the main installation or update flow
- `bootstrap.post_install` — runs after AIAST is installed into a repo
- `bootstrap.post_update` — runs after AIAST is updated in a repo

### Validation hooks
- `validation.preflight` — runs before the main validation suite
- `validation.postflight` — runs after the main validation suite
- `validation.report` — contributes to the final validation diagnostic report

### Security hooks
- `security.scan` — runs during security scanning
- `security.audit` — runs during security audit

### CI hooks
- `ci.pre_commit` — runs before commit hooks
- `ci.post_test` — runs after the test suite completes

### Testing hooks
- `testing.pre_run` — runs before the test suite, can inject fixtures or environment

### Documentation hooks
- `documentation.generate` — contributes to generated documentation

### Monitoring hooks
- `monitoring.setup` — configures observability surfaces (health endpoints, logging, metrics)

### Environment hooks
- `environment.validate` — checks runtime environment prerequisites (ports, tools, databases)

## Lifecycle

### Discovery
- `bootstrap/discover-plugins.sh` scans `_system/plugins/*/plugin.json` and reports status.
- Plugins are discovered automatically during `system-doctor.sh` runs.

### Validation
- `bootstrap/validate-plugin.sh <plugin-dir>` validates a plugin against this contract.
- Checks: manifest schema, hook-point names, owned_path conflicts, version compatibility.

### Execution
- Plugins with `run.sh` are invoked by the corresponding hook trigger.
- Each plugin runs as a separate bash process.
- Non-zero exit from a plugin produces a warning, not a fatal error.
- Plugin output is captured and included in diagnostic reports.

### Enable / Disable
- Set `"enabled": false` in `plugin.json` to disable without removing.
- Disabled plugins are discovered but not executed.

## Rules

- Plugins must not mutate runtime code unless explicitly invoked for repo generation.
- Plugin-owned files must be declared in `owned_paths`.
- Plugin files must not bypass integrity, security, or upgrade policy.
- Core AIAST files remain authoritative on conflicts unless the repo explicitly adopts the plugin-owned path.
- Plugin failures must not break core validation or bootstrap flows.
- Plugins must declare their minimum compatible AIAST version in `aiast_min_version`.
- Plugins must not add entries to the AIAST required-file list; they manage their own file tracking.

## Creating a new plugin

1. Create `_system/plugins/<name>/plugin.json` with the required fields.
2. Create `_system/plugins/<name>/README.md` describing purpose and usage.
3. Optionally create `_system/plugins/<name>/run.sh` for executable hooks.
4. Run `bootstrap/validate-plugin.sh _system/plugins/<name>` to verify.
5. Run `bootstrap/discover-plugins.sh .` to confirm discovery.
