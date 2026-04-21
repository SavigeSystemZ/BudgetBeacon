# CI Templates

These templates stay under `_system/ci/` so repos can adopt them intentionally instead of receiving root-level CI files by default.

## Included

- `github-actions/ci.yml.example`
- `github-actions/release.yml.example`
- `github-actions/linux-packaging.yml.example`
- `github-actions/android.yml.example`
- `gitlab-ci.yml.example`

## Expected jobs

- lint or format verification
- type checking
- unit and integration testing
- build verification
- packaging verification
- systemd hardening and manifest syntax verification
- Android build smoke when `mobile/` exists
- security scan hook via `bootstrap/scan-security.sh`
