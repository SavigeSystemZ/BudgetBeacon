# Release Notes

> _Timestamp: 2026-06-02. Release notes for **Budget Beacon**. (Prior contents were the AIAST template's own release notes, carried in by the template sync; replaced with this app's release posture.)_

## Current release target

- **Target label:** `v1.0.0` — first hardened public build.
- **Distribution:** sideload **APK** published via **GitHub Release** (no Play Store / AAB) + PWA install. See the Final Hardening plan in `_system/context/AGENT_SHARED_MEMORY.md`.
- **Status:** **Not yet released.** Budget Beacon is in the Final Hardening pass (Phase 2 remainder → M10 sync, M11 joint household, M12 release). `v1.0.0` is tagged only after the M12 checklist passes, which triggers `.github/workflows/android-release.yml` to publish the signed APK + `mappings.txt` + SHA-256 checksums.
- **Audience:** the operator and households running a local-first, private budgeting app.

## What v1.0.0 is intended to include

- Local-first budgeting core: budgets/categories, transaction ledger, month-to-date spend vs budget, reporting — all on-device via Dexie/IndexedDB.
- Opt-in end-to-end-encrypted sync (Option B / CRDT) with a small relay; local-only remains the default.
- Recovery codes (single-use, KEK-encrypted) and an onboarding flow that branches local-only vs sign-up.
- Joint-household sharing with per-record ownership and an activity log.
- Hardened Android build: R8/ProGuard, env-based keystore signing, tightened manifest.

## Honesty note

- Several advanced surfaces have historically been mocked (assistant provider, bank/credit fetch, OCR, some exports). These must be real and verified before being described as shipped — see `TODO.md` and `FIXME.md`. Do not list a capability here until it is implemented and tested.

## Known limitations (pre-release)

- No signed release artifact exists yet; treat all builds as development.
- Sync, recovery, and joint-household flows are in progress per the phased plan.
