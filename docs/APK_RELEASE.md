# APK release pipeline

This document is the operator contract for cutting a Budget Beacon Android
release. Phase 1 of the Final Hardening pass moved every signing secret out of
source control; reproducing a release now requires the credentials below and
nothing more.

## ⚠️ Hard requirement before v1.0.0

The previous release keystore (`android/app/release-key.keystore`) and its
password (`beacon_secure_123`) were committed to git history through commit
`6637da9` and earlier. **Treat that keystore as compromised.** Before publishing
a public v1.0.0:

1. Generate a brand-new keystore (instructions below).
2. Discard the old keystore file from disk and any backups.
3. Re-sign all distribution APKs with the new keystore.
4. Note in `RELEASE_NOTES.md` that the published key is rotated.

## Local prerequisites

- JDK 21 (Temurin recommended).
- Android command-line tools / Android Studio (for `keytool`, `gradle`).
- Node 20+ and `npm ci` installed.

## Generate a fresh keystore

```bash
keytool -genkeypair \
  -keystore release.keystore \
  -alias budgetbeacon \
  -keyalg RSA -keysize 4096 -validity 10000 \
  -storepass "<STRONG_RANDOM>" -keypass "<STRONG_RANDOM>" \
  -dname "CN=Budget Beacon, O=AIAAST, L=Unknown, ST=Unknown, C=US"
```

Store the keystore in a password manager / secret store, **not** in the repo.
The file is gitignored (`*.keystore`, `*.jks`, `keystore.properties`) but never
trust the gitignore — also verify with `git check-ignore release.keystore`.

## Configure local builds

Two equivalent ways to wire credentials into `android/app/build.gradle`:

### Option A — environment variables (CI default)

```bash
export BEACON_RELEASE_KEYSTORE_FILE=$HOME/secrets/budget-beacon/release.keystore
export BEACON_RELEASE_KEYSTORE_PASSWORD=...
export BEACON_RELEASE_KEY_ALIAS=budgetbeacon
export BEACON_RELEASE_KEY_PASSWORD=...
```

### Option B — repo-root `keystore.properties`

```properties
storeFile=/abs/path/to/release.keystore
storePassword=...
keyAlias=budgetbeacon
keyPassword=...
```

`keystore.properties` is gitignored. Either form works locally; CI uses Option
A exclusively (see `.github/workflows/android-release.yml`).

## Build commands

```bash
# Build web bundle + capacitor sync, then assemble + sign release APK
npm run android:assemble:release

# Lint the release variant only (used in CI)
npm run android:lint:release

# Audit baselines run before any release
npm run validate
npm run audit:controls
npm run audit:secrets
```

The signed APK lands at
`android/app/build/outputs/apk/release/app-release.apk`. The R8 mapping for
deobfuscating crash reports lands at
`android/app/build/outputs/mapping/release/mapping.txt` — keep this for every
released build.

## Versioning

`versionName` and `versionCode` derive from `package.json#version`:

- `versionName` mirrors the semver string verbatim (e.g. `1.0.0`).
- `versionCode` is `MAJOR*10000 + MINOR*100 + PATCH` (e.g. `1.0.0` → `10000`,
  `1.2.3` → `10203`). Monotonic across all sane semver bumps. See
  `derivePackageVersion` in `android/app/build.gradle`.

To cut a release: bump `package.json#version`, commit, tag `vX.Y.Z`, push the
tag. The `android-release.yml` workflow takes it from there.

## CI release workflow

`.github/workflows/android-release.yml` triggers on tag `v*` and:

1. Runs `npm run validate` + `npm run audit:controls` + `npm run audit:secrets`.
2. Decodes `BEACON_RELEASE_KEYSTORE_BASE64` (a GitHub Actions secret) into a
   temp keystore file.
3. Assembles `:app:lintRelease` + `:app:assembleRelease`.
4. Uploads the signed APK + SHA-256 + R8 mapping to the GitHub Release.

### Required GitHub Actions secrets

- `BEACON_RELEASE_KEYSTORE_BASE64` — `base64 release.keystore` (no line wraps).
- `BEACON_RELEASE_KEYSTORE_PASSWORD`
- `BEACON_RELEASE_KEY_ALIAS`
- `BEACON_RELEASE_KEY_PASSWORD`

Generate the base64 form with `base64 -w0 release.keystore` (Linux) or
`base64 -i release.keystore | tr -d '\n'` (macOS).

## Distribution policy (this pass)

- Sideload APK only. No Play Store / AAB this milestone.
- Each release attaches: `app-release.apk`, `app-release.apk.sha256`,
  `mapping.txt`. Users verify the SHA-256 before sideloading.
- `docs/INSTALL.md` (added in Phase 5) is the user-facing install guide.

## Pre-flight checklist

Before pushing a `v*` tag:

- [ ] `npm run validate` green.
- [ ] `npm run audit:controls` green.
- [ ] `npm run audit:secrets` green.
- [ ] `package.json#version` bumped.
- [ ] `CHANGELOG.md` updated.
- [ ] `RELEASE_NOTES.md` checklist ticked.
- [ ] Two-emulator parity smoke pass on `Pixel 7 / API 34` (per
      `docs/M9_ANDROID_QA_CHECKLIST.md` § "M10/M11 emulator parity smoke").
- [ ] Threat model (`docs/THREAT_MODEL.md`) reviewed.
- [ ] If signing key was rotated, note it in the release body.
