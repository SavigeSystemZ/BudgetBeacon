# Installer And Upgrade Contract

This contract defines what AIAST lifecycle commands are allowed to change and
what they must preserve.

For **shipped applications** built in the repo (end-user install, multi-OS
delivery, operator menus), use `CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md`
in addition to this file.

## Lifecycle modes

- First install: copy the AIAST operating layer into a repo that does not have
  it yet.
- Additive backfill: add newly introduced managed files without overwriting
  repo-owned truth.
- Update: refresh versioned template-managed files from a canonical source,
  optionally including broader managed drift when explicitly requested.
- Repair: restore required managed files or metadata after damage or accidental
  deletion.
- Heal: run doctor checks and then apply the safest repair path available.

## State preservation guarantees

- Never overwrite repo-owned working files such as `PLAN.md`, `TODO.md`, or
  `_system/context/*.md` as part of a normal upgrade.
- Never silently replace `_system/PROJECT_PROFILE.md`.
- Never treat host-local orchestration prompts as more authoritative than the
  repo-local operating layer.
- Always regenerate machine-readable metadata after lifecycle mutations:
  `_system/SYSTEM_REGISTRY.json`, `_system/KEY.md`,
  `_system/repo-operating-profile.json`, and
  `_system/INTEGRITY_MANIFEST.sha256`.

## Smart entrypoint

`bootstrap/scaffold-system.sh` is the preferred human-facing lifecycle command.
It should choose between first install, additive backfill, or update based on
the target state and the available canonical template source.

## Required post-action checks

- `bootstrap/validate-system.sh <repo> --strict`
- `bootstrap/check-system-awareness.sh <repo>`
- `bootstrap/validate-instruction-layer.sh <repo>`

## Explicit review required

- using `--refresh-managed` on a drifted installed repo
- replacing bootstrap scripts the repo may have patched locally
- touching prompt-emission or adapter-generation surfaces
- any lifecycle action where the canonical template source is uncertain
