# Flutter Module

This is a minimal foundation, not a full production app.

## First steps

1. From `mobile/flutter/`, run `flutter create --platforms=android .` to
   generate the missing Flutter and Gradle project files around this AIAST
   foundation.
2. Run `flutter pub get`.
3. Replace the placeholder API host and package ids.
4. Add app icons and signing config.
5. Wire the UI to your actual runtime service or API.

## Flavors

- `dev` for local or QA endpoints
- `prod` for release endpoints

## Commands

- `flutter run`
- `flutter build apk --flavor prod`
- `flutter build appbundle --flavor prod`
