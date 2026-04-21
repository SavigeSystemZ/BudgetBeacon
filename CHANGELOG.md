# Changelog

Use this file for meaningful repo-visible change history. Keep transient task chatter in `TODO.md` or `WHERE_LEFT_OFF.md`.

## Unreleased

- None recorded yet.

## 1.22.1 (2026-04-12)

- Patch release: closes the downstream-proof fixes uncovered by the first
  `1.22.0` replay and aligns installable semver markers with source tag
  **`v1.22.1`**.
- `bootstrap/update-template.sh` now repairs managed-file mode drift even when
  content already matches the source template, so executable bootstrap surfaces
  recover their `+x` bit during downstream refreshes.
- Integrity manifests now track the real managed installable surface instead of
  transient bytecode or repo-local runtime trees; `distribution/`, `docs/`,
  `notes/`, `.credits-hidden`, `LICENSE`, and `NOTICE` are included.
- Downstream proof on `CandleCompass` exposed and closed the installed-doc
  boundary leak around hard-coded master-template paths; the proof playbook now
  requires sanitizing installed continuity docs when strict validation catches a
  forbidden maintainer source-clone path.

## 1.22.0 (2026-04-12)

- Minor release: preservation-first governance hardening imported from SACST in
  adapted form only, without sysadmin-domain contamination.
- Added `_system/READ_BUNDLES.md`,
  `_system/TEMPLATE_CHANGE_IMPACT_POLICY.md`,
  `_system/SELF_HEALING_BOUNDARY.md`, and
  `_system/VERSION_SENSITIVE_RESEARCH_PROTOCOL.md`.
- Added maintainer-only learning-loop, promotion, harvest-policy, and donor-review
  surfaces in the master-repo meta workspace, plus factory checks
  `_TEMPLATE_FACTORY/check-template-impact.sh` and
  `_TEMPLATE_FACTORY/check-promotion-readiness.sh`.
- Tightened precedence, prompt-emission, host-bundle, load-order,
  operating-profile, awareness, and conflict-detection surfaces so bundle,
  repair, research, and promotion governance stay aligned.
- Regenerated host adapters, `_system/KEY.md`, `_system/SYSTEM_REGISTRY.json`,
  `_system/repo-operating-profile.json`, and `_system/INTEGRITY_MANIFEST.sha256`
  for the 1.22.0 surface.
- `_TEMPLATE_FACTORY/run-maintainer-lane.sh` and
  `_TEMPLATE_FACTORY/run-automation-lane.sh` both passed on 2026-04-12.

## 1.21.1 (2026-04-06)

- Patch release: installable semver and JSON markers (`AIAST_VERSION.md`,
  `_system/.template-version`, `instruction-precedence.json`, `.template-install.json`,
  `aiaast-capabilities.json`) aligned with git tag **`v1.21.1`**; plugin manifests
  `aiast_min_version` **1.21.1**; includes pinned-source upgrade documentation in
  `UPGRADE_AND_DRIFT_POLICY.md` and `GIT_REMOTE_AND_SYNC_PROTOCOL.md` (see
  `AIAST_CHANGELOG.md`).
