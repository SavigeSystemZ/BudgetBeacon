# Mobile Guide

Flutter is the default Android-first mobile path for AIAST scaffolds.

## Generated structure

- `mobile/README.md`
- `mobile/flutter/pubspec.yaml`
- `mobile/flutter/lib/main.dart`
- `mobile/flutter/android/app/src/main/AndroidManifest.xml`

The copied mobile foundation is intentionally minimal. From `mobile/flutter/`,
run `flutter create --platforms=android .` before expecting `flutter analyze`,
`flutter test`, or `flutter build apk --debug` to work.

## Release expectations

- Support `dev` and `prod` flavors.
- Keep signing keys out of version control.
- Build debug APKs for local validation and AABs for store distribution.
- Reuse the same backend API contracts as desktop or web clients where possible.

## Publishing reminders

- Review privacy disclosures and data collection requirements.
- Keep app ids and icons project-specific.
- Test on at least one emulator and one physical Android device before release.
