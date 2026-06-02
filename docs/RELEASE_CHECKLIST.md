# M12 Release Checklist

Before tagging `v1.0.0`, ensure the following criteria are met:

- [x] **Documentation Complete**: `THREAT_MODEL.md`, `INSTALL.md`, and `RECOVERY.md` have been reviewed and published.
- [x] **M11 Complete**: Joint households feature implemented with secure offline ECDH key exchange.
- [x] **Validation Passes**: `npm run validate` executes flawlessly (0 lint errors, 0 type errors, all unit tests pass, and prod build is successful).
- [x] **Audit Controls**: `npm run audit:controls` and `npm run audit:secrets` produce clean results aligning with baselines.
- [x] **CI Configuration**: `.github/workflows/android-release.yml` is correctly configured to catch tags starting with `v*` and assemble the release APK.
- [x] **Capacitor Sync**: Web assets are successfully synced into the Android project using `npx cap sync android`.
- [x] **Android Visuals Verified**: UI checked on an Android emulator or device to ensure proper safe-area padding and visual fidelity.

## Tagging & Releasing

1. Ensure all changes are committed to the `main` branch.
2. Create an annotated tag for the release:
   ```bash
   git tag -a v1.0.0 -m "Budget Beacon v1.0.0: M10 and M11 Completed"
   ```
3. Push the tag to GitHub:
   ```bash
   git push origin v1.0.0
   ```
4. GitHub Actions will automatically trigger `.github/workflows/android-release.yml` to build the APK and draft a release.
5. Review the drafted release on GitHub, attach the APK if not automatically attached, and publish.
