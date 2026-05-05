# Upgrade and Drift Policy

How to keep installed repos current with the master AIAST template without losing app-specific state.

For the **downstream preservation doctrine**, sync notice file, and mandatory
agent health gate after installs/updates, read
`DOWNSTREAM_PRESERVATION_AND_SYNC_NOTICE_POLICY.md`.

For a single map of install vs upgrade vs repair entry points, read `INSTALLER_AND_UPGRADE_CONTRACT.md`.

## Version tracking

- `AIAST_VERSION.md` is the human-readable release marker for the template.
- `_system/.template-version` is the installed machine-readable version marker.
- `_system/.template-install.json` records source template path, timestamps, install mode, and system README placement.

## Pinning the source template (release tags)

The AIAST **source** repository publishes annotated release tags (for example **`v1.21.0`**) for reproducible milestones. When you want upgrades or drift checks to match a **documented** snapshot instead of whatever tip `main` happens to point at:

1. In the machine-local clone you use as `--source` for `update-template.sh` / `detect-drift.sh`, fetch tags: `git fetch origin --tags`.
2. Check out the tag: `git switch --detach v1.21.0` (or `git checkout v1.21.0`).
3. Point `--source` at the `TEMPLATE/` directory inside that checkout.

Using a moving `main` checkout is fine for bleeding-edge adoption; pinned tags are better for **reproducible** comparisons, support handoffs, and bug reports. Note which tag you used in `WHERE_LEFT_OFF.md` or upgrade notes when debugging drift.

## Upgrade path

When the master template gains new files or improvements:

1. Run `bootstrap/update-template.sh <repo> --source <master-template> --dry-run`.
2. Review missing files, drifted template-managed files, and version skew.
3. Apply additive updates first.
4. Use `--refresh-managed` only when you intend to overwrite drifted template-managed files from the source template.
5. Run `bootstrap/validate-system.sh <repo> --strict`.
6. Run `bootstrap/detect-drift.sh <repo> --source <master-template>` to confirm the post-upgrade state.

## What upgrades safely

- New `_system/` governance files
- New review playbooks, prompt packs, prompt templates, starter blueprints
- New `.cursor/` commands, skills, agents, rules
- New bootstrap scripts
- New CI, packaging, systemd, observability, and plugin-contract scaffolds

## What requires manual review

- Drifted template-managed files in the target repo
- Changed `AGENTS.md` or tool entry files with repo-specific additions
- Changed bootstrap scripts that the repo may have patched locally
- Repo-generated files copied out of `_system/` into runtime locations

## What never upgrades from source content

- `_system/PROJECT_PROFILE.md`
- working files (`TODO.md`, `WHERE_LEFT_OFF.md`, `PLAN.md`, etc.)
- `_system/context/*.md` state surfaces
- `.cursor/mcp.json`
- `_system/.template-install.json`
- `_system/SYSTEM_REGISTRY.json` as raw content — regenerate it locally instead

## Drift classes

- Structural drift: template files are missing from the installed repo
- Content drift: template-managed files differ from the chosen source template
- Integrity drift: installed template-managed files no longer match the repo’s integrity manifest
- Version skew: installed version differs from the source template version
- Stale drift: status/context files are outdated or missing timestamps

## Response guide

- Structural drift: `bootstrap/install-missing-files.sh`
  This now also recreates missing generated runtime scaffolds and reseeds safe onboarding defaults for restored files.
- Content drift: `bootstrap/update-template.sh --dry-run`, then optionally `--refresh-managed`
- Integrity drift: `bootstrap/repair-system.sh --dry-run`
- Version skew: `bootstrap/update-template.sh --dry-run`
- Retirement: `bootstrap/uninstall-system.sh --backup-state --leave-tombstone`
