# Linux distribution

## Install scripts

Use `ops/install/install.sh` (and `repair.sh`, `uninstall.sh`, `purge.sh`) for
loopback-first deployment, port allocation, and optional systemd units.

## Desktop packages

Build artifacts from `packaging/` (`flatpak-manifest.json`, `appimage.yml`,
`snapcraft.yaml`) for end-user distribution.

## Architectures

Ship or CI-build for `x86_64` and `aarch64` where applicable; document `armv7l`
only if the product explicitly supports it.

See `_system/CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md`.
