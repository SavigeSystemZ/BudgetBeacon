# iOS distribution

Apple platforms require **Xcode**, signing identities, and App Store Connect or
enterprise program workflows. There is no generic shell “installer” equivalent.

## Conventions

- Keep bundle identifiers aligned with `__AIAST_APP_ID__` after review.
- Document TestFlight vs App Store vs enterprise distribution in release docs.

## Relation to repo

- Implementation lives under `mobile/` (Flutter) or a future `ios/` native tree.
- This folder holds **release and compliance notes** only unless you add
  Fastlane or Xcode project stubs.

See `_system/CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md` and
`MOBILE_GUIDE.md`.
