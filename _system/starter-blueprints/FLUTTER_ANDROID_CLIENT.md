# Flutter Android Client Blueprint

Use this when the project needs a native-feeling Android client with a shared backend contract.

## Expected repo shape

```text
mobile/
  flutter/
    lib/
      app/
      features/
      services/
      widgets/
    android/
```

## Stack signals

- Primary languages: Dart, Kotlin
- Primary frameworks: Flutter
- Build tools: Flutter SDK, Gradle
- Deployment target: Android

## Quality expectations

- Separate feature state from transport code.
- Keep API client code under `services/`.
- Support loading, empty, error, and offline states for every core screen.
- Use adaptive spacing and touch-friendly hit targets.
- Keep release and debug flavors separate.

## Bootstrap note

- AIAST copies a minimal Flutter foundation, not a complete generated Flutter
  project.
- From `mobile/flutter/`, run `flutter create --platforms=android .` before
  expecting `flutter analyze`, `flutter test`, or `flutter build apk --debug`
  to work.
- After generation, replace the default Android namespace and application id
  with the repo-specific values recorded in `_system/PROJECT_PROFILE.md`.

## Validation commands

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`

## First milestone suggestion

- Render one branded shell screen
- Connect one API-backed feature flow
- Confirm debug APK builds successfully
- Confirm app id, version, and manifest permissions are project-specific
