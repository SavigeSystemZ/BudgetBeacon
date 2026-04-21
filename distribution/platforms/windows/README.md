# Windows distribution

## Script entry

- `Install.ps1` — scaffold installer with elevation check, optional port
  selection, and transcript logging.
- Production: replace or wrap with **MSIX**, **WiX MSI**, or **winget**
  manifests for signed distribution.

## Paths

Prefer `%ProgramFiles%\Budget Beacon` for per-machine installs and
`%LOCALAPPDATA%\Programs\Budget Beacon` for per-user installs when not
using an MSI.

## Ports

Avoid hardcoding. Persist chosen ports under the app config directory and
document overrides in operator docs.

See `_system/CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md`.
