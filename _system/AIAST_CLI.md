# AIAST Operator CLI (`aiast`)

`bootstrap/aiast` is the single operator front-door over the `bootstrap/`
script surface. Operators and downstream agents type one discoverable command
instead of memorizing individual script names. It resolves every target
relative to its own directory, so it behaves identically in the TEMPLATE
source and in every scaffolded downstream repo.

## Usage

```
bootstrap/aiast                 # grouped command catalog (same as `help`)
bootstrap/aiast help            # grouped command catalog
bootstrap/aiast list [--json]   # machine-readable curated manifest
bootstrap/aiast all             # every bootstrap/*.sh (raw surface)
bootstrap/aiast version         # installed template version
bootstrap/aiast status [TARGET] # quick posture: version + gate + doctor
bootstrap/aiast <verb> [args…]  # dispatch; args pass straight through
```

## Curated verbs

| Group | Verb | Maps to |
|---|---|---|
| Health & validation | `doctor` | `system-doctor.sh` |
| Health & validation | `validate` | `validate-system.sh` |
| Health & validation | `env` | `check-environment.sh` |
| Health & validation | `status` | builtin (version + gate + doctor) |
| Meta-sync | `meta-sync-gate` | `check-pending-meta-sync.sh` |
| Meta-sync | `reconcile` | `reconcile-meta-sync.sh` |
| Meta-sync | `update` | `update-template.sh` |
| Host settings | `host-settings` | `apply-host-settings.sh` |
| Host settings | `host-settings-check` | `check-host-settings-baseline.sh` |
| Agent coordination | `orchestration` | `check-agent-orchestration.sh` |
| Agent coordination | `lock` / `unlock` | `agent-lock.sh` / `agent-unlock.sh` |
| Agent coordination | `heartbeat` | `agent-heartbeat.sh` |
| Lifecycle | `install` | `install-aiast.sh` |
| Lifecycle | `scaffold` | `scaffold-system.sh` |
| Lifecycle | `version` | builtin |
| Meta | `help` / `list` / `all` | builtins |

The curated set is intentionally small — a front-door, not a mirror of all
157 scripts. Power users who need a script with no curated verb run
`aiast all` to list the full raw surface and invoke it directly.

## Contract

- **Exit codes:** builtin success `0`; unknown command `2` (with did-you-mean);
  dispatched commands return the **child script's own exit code** unchanged.
- **Result tokens:** builtins emit `aiast_cli_ok command=<name>` on success and
  `aiast_cli_error reason=<r> command=<c>` on failure (stderr).
- **Passthrough:** everything after the verb is forwarded verbatim via `exec`,
  so child flags (`--json`, `--strict`, `--force`, …) work unchanged.
- **Integrity:** `bootstrap/aiast` is a managed file — registered in
  `_system/SYSTEM_REGISTRY.json` and `_system/INTEGRITY_MANIFEST.sha256`.
  After editing it, regenerate contracts with
  `bootstrap/sync-metasystem-contracts.sh <repo> --write`.

## Acceptance

`_TEMPLATE_FACTORY/smoke-aiast-cli.sh` (8 cases) is wired into the master
validation lane; expect `aiast_cli_smoke_ok cases=8`.
