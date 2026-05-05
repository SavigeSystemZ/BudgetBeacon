# Android distribution — Budget Beacon

Budget Beacon ships as a **sideload APK** (no Play Store / AAB this milestone).
Capacitor-wrapped React PWA, Java 21, minSdk 24 / targetSdk 36, R8-shrunk in
release.

## How releases are built

The full operator contract lives at [`docs/APK_RELEASE.md`](../../../docs/APK_RELEASE.md).
The short version:

- `package.json#version` is the single source of truth for `versionName` and
  `versionCode` (`MAJOR*10000 + MINOR*100 + PATCH`).
- Release keystore credentials come from env vars (`BEACON_RELEASE_KEYSTORE_*`)
  or a gitignored `keystore.properties`. Never inline.
- `.github/workflows/android-release.yml` is the canonical build lane:
  triggered by tag `v*`, runs `validate` + `audit:controls` + `audit:secrets`,
  assembles + signs, and publishes APK + SHA-256 + R8 mapping to the GitHub
  Release.
- `.github/workflows/android-emulator-smoke.yml` is the per-PR safety net:
  builds the debug APK and boots it on a `Pixel 7 / API 34` emulator.

## How users install

Sideload from the GitHub Release. Verification flow lives in
[`docs/INSTALL.md`](../../../docs/INSTALL.md) once Phase 5 lands.

See also `_system/CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md` for
the cross-platform distribution model.
