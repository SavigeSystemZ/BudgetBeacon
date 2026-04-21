# Mobile

This scaffold uses Flutter as the default Android-first mobile path.

## Included

- `flutter/` minimal starter files
- Android manifest with placeholder identifiers
- guidance for dev and prod flavors
- a minimal foundation that still needs
  `flutter create --platforms=android .` inside `mobile/flutter/` before the
  full Android project files exist

## Expectations

- Keep secrets and signing keys outside the repository.
- Replace placeholder package ids and icons before release.
- Use the same backend API contract as the desktop or web clients when possible.

## Release outputs

- debug APK for local testing
- release APK for direct distribution
- release AAB for Play publishing
