# Packaging Guide

Ship packages, not ad hoc source installs, whenever the project is release-ready.

## Linux targets

- Native packages where the stack has strong tooling: `.deb`, `.rpm`
- Universal packages for desktop distribution: AppImage, Flatpak, Snap

## Template defaults

- Generated app manifests live under `packaging/`
- Flatpak is the first deeply documented and CI-friendly path
- Signing keys stay outside the repository

## Minimum validation

- Manifest syntax check
- Build artifact smoke test in CI
- Install or launch smoke test in a clean environment
- Signature or checksum publication for release artifacts

## Publishing

- Flatpak: Flathub or internal repo
- Snap: Snapcraft store or internal channel
- AppImage: signed release artifacts with checksums
- Android: APK or AAB through direct distribution, F-Droid, or Play
