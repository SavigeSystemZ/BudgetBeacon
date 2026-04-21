# Packaging Guide

Package finished applications instead of relying on ad hoc source installs.

See also:

- `../PACKAGING_GUIDE.md`
- `templates/appimage.yml.example`
- `templates/flatpak-manifest.json.example`
- `templates/snapcraft.yaml.example`

## Native Linux packages

- Python: wheel and sdist first, then `.deb` or `.rpm` with tools such as `fpm` or distro-native helpers
- Rust: prefer release binaries with optional `cargo-deb` and `cargo-rpm`
- Go: prefer release binaries with optional `goreleaser`

## Universal Linux bundles

- AppImage: self-contained binary distribution
- Snap: sandboxed distribution through snapd
- Flatpak: desktop-oriented sandboxed distribution

## Validation

- Build package artifacts in CI
- Verify install or launch in a clean environment
- Sign or checksum release artifacts where possible

## Templates

- `templates/appimage.yml.example`
- `templates/flatpak-manifest.json.example`
- `templates/appimage-builder.yml.example`
- `templates/snapcraft.yaml.example`
- `templates/flatpak.yaml.example`

When the Flatpak manifest lives under `packaging/`, keep its source dir rooted
at `..` so repo-root artifacts like `dist/<app>` remain part of the build
context.
