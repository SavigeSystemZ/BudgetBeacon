# Tauri Desktop Blueprint

Use this for Linux-first desktop apps that need a native-feeling shell around a web UI.

## Expectations

- Separate frontend and native shell concerns cleanly
- Package targets decided early for AppImage, Snap, or Flatpak where relevant
- Local data, settings, and logs stored in platform-appropriate locations
- Window, tray, deep-link, and update behavior documented explicitly

## Validation commands

- Frontend build and typecheck
- Tauri build verification
- Desktop smoke launch on the target OS

## First milestone suggestion

1. Render one production-like screen in the desktop shell.
2. Verify build and local launch on Linux.
3. Define packaging and update strategy in the profile.
