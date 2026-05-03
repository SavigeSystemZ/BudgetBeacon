# M9 — Android / Capacitor QA checklist (pre-sync)

Use this on a **physical device** (or emulator with realistic constraints). Budget Beacon ships **local-first**; there is **no** cloud sync until **M10** is approved.

## Environment

- [ ] Release or debug APK from `npx cap sync android` + Android Studio install.
- [ ] Note device model, Android version, available RAM, and free storage.
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
