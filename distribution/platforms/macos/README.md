# macOS distribution

## Recommended channels

- **Developer ID signed** `.pkg` or **notarized** app bundle for direct download.
- **Homebrew** cask or formula for CLI/server tools when the project maintains a tap.

## Layout

- `/Applications/Budget Beacon.app` for GUI apps.
- `/usr/local` or `/opt/homebrew` prefixes for CLI tools per Apple Silicon vs Intel norms.

## Hardening

- Enable Hardened Runtime, declare entitlements explicitly, and document why each
  entitlement exists.

See `_system/CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md` and
`PACKAGING_GUIDE.md`.
