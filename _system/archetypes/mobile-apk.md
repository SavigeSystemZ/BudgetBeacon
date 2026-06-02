# Archetype Pack: mobile-apk

## App purpose
Android APK delivery with secure permissions and resilient mobile UX.
## Required docs
- MobileGuide, PermissionPolicy, ReleaseSigning, Privacy
## Required runtime surfaces
- mobile client, API integration, crash telemetry
## Recommended stack options
- Flutter + API backend
## Security/privacy posture
- minimum permission set, encrypted local storage
## Installer expectations
- emulator smoke + signed artifact readiness
## Port policy
- client-safe defaults, no exposed local services by default
## Validation gates
- lint/test/apk-build/emulator-smoke
## UI/UX completion requirements
- responsive layouts, offline handling, clear errors
## Platform expectations
- Android-first
## Fleet roles
- mobile-dev, QA, release-steward
## Prompt-pack hooks
- mobile and release readiness packs
## Benchmark/test-app scenario
- AIAST-Test-MobileAPK
## Anti-patterns
- overbroad permissions, unsigned production builds
