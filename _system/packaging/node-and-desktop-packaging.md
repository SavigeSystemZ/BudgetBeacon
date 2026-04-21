# Node and Desktop Packaging Notes

- For services, package the runtime app and service wrapper separately from secrets and environment files.
- For Electron or Tauri, produce desktop bundles first, then AppImage, Snap, or Flatpak where relevant.
- Keep package verification in CI and smoke-test the produced artifact before release.
