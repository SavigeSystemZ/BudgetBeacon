# M9 — Android / Capacitor QA checklist (pre-sync)

> **2026-05-05 amendment:** the **Android emulator (Pixel 7 / API 34)** is the accepted M9 verification surface for the v1.0.0 release. Run every step below on the emulator first. Physical-device runs remain a recommended stretch but no longer block the milestone. Note any emulator-only caveats (low-end RAM, biometrics, real network jitter) explicitly when signing off.

Use this on the emulator (or a physical device when available). Budget Beacon ships **local-first**; cloud sync (M10) is opt-in and uses an end-to-end-encrypted relay.

## Environment

- [ ] **Emulator baseline:** Android Studio AVD `Pixel 7 / API 34` (Android 14), 4 GB RAM, 8 GB internal storage, swiftshader_indirect graphics. Wipe data before each cold-install run.
- [ ] Build the **signed release APK** via `gradlew :app:assembleRelease` (Phase 1 release lane), not just debug.
- [ ] Note emulator config (AVD name, API level, RAM, accel), and (when applicable) physical device model + Android version.
- [ ] Fresh install vs upgrade from previous APK (both paths if time allows).

## Shell & navigation

- [ ] App cold start & warm resume from recents (no white screen / stuck splash).
- [ ] Bottom nav + hamburger / “Terminal” full menu: every route reachable.
- [ ] Back gesture / hardware back: does not exit app unexpectedly from nested modals.
- [ ] Hash routes (`#/ledger`, etc.) restore after process death.

## Safe area & layout

- [ ] Notch / punch-hole: `PageHeader` actions and floating Beacon FAB not clipped.
- [ ] `env(safe-area-inset-bottom)` — bottom nav and chat FAB clear home indicator.
- [ ] Landscape: critical screens usable (Dashboard, Ledger import, Settings).

## Data & persistence

- [ ] Create household → survives force-stop and relaunch.
- [ ] Settings toggles + AI config persist across relaunch.
- [ ] **Backup export** downloads/opens share sheet; file is non-empty JSON.
- [ ] **Restore** preview → confirm → data replaced as expected (use disposable household).

## Ledger import (Tier A stress)

- [ ] CSV import: mapping → review → commit on medium file (≥200 rows).
- [ ] OFX import: structured path skips column mapping; amounts sign correctly.
- [ ] Large paste / slow SD card: UI stays responsive; no duplicate commits on double-tap.

## Vault & OCR (memory / CPU)

- [ ] Upload PDF or image; OCR progress visible; cancel does not corrupt DB.
- [ ] Approve extraction → rows appear in Income / Pay Path / Tax with provenance.
- [ ] Low-memory warning path: Tesseract failure surfaces readable error (no silent hang).

## Assistant

- [ ] With Ollama/LAN URL: streaming renders; stop button aborts.
- [ ] Without provider: placeholder reply shows aggregates (no crash).
- [ ] Long chat scroll: no jank when history grows.

## PWA (if testing browser build on Android)

- [ ] “Add to Home screen” launches standalone.
- [ ] Offline after first load: shell loads; Dexie operations still work.

## Regression snapshot

- [ ] `npm run validate` green on host before tagging a release candidate.
- [ ] Record failures + screenshots in `FIXME.md` or issue tracker with device details.

---

_When M10 lands, extend this checklist with: login, relay disconnect, multi-device conflict, and encrypted backup restore across accounts._

## M10/M11 emulator parity smoke (added 2026-05-05)

Run two emulator instances (`Pixel 7 / API 34` × 2, distinct AVD names) with the deployed relay reachable:

- [ ] Instance A signs up with passphrase → Settings → Start sync; relay status badge transitions Connecting → Synced.
- [ ] Instance A downloads recovery sheet; verify 10 codes are distinct and printable.
- [ ] Instance A creates 5 transactions, 2 bills, 1 goal; observe Yjs/Dexie convergence (no console errors).
- [ ] Instance B logs in with same passphrase → data appears within ≤2 s on LAN.
- [ ] Edit on each side concurrently → CRDT merge resolves without dupes; counts match.
- [ ] **M11:** Instance A invites Instance C via QR code (24 h, single-use); C accepts → joins household.
- [ ] **M11 leave:** C leaves; key rotates; A's stale invite token rejected; activity log records the event with author.
- [ ] Backup export v4 round-trips on each instance independently.
- [ ] Force-stop relay → both clients show "Offline" pill, queue local writes, reconcile on reconnect.
