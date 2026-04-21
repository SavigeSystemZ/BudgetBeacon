# Android distribution

Mobile deliverables are **not** the same installer model as desktop Linux.

## Source of truth

- Flutter or native project under `mobile/` (see `MOBILE_GUIDE.md`).
- Ship **AAB** to Play Console or **APK** for sideloading / enterprise MDM.

## Installer meaning here

- CI pipelines that bump `versionCode`, sign with release keys, and upload.
- Optional in-app first-run that collects only **required** operator input
  (endpoint URL, API key) with secure storage.

See `_system/CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md`.
