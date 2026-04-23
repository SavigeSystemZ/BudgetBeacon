# TODO

This is the active execution queue. Keep it tight, factual, and ordered.
Use priority signals: **CRITICAL**, **HIGH**, **MEDIUM**, **LOW**.

## Current Priority

- [ ] HIGH: Verification of VA Assistance Seed Data (Confirm exact values for property tax, SimpliSafe, Aaron's, etc.).

## Immediate Queue

- [ ] MEDIUM: Attach Kehley M. Smith's Market Basket pay stubs and SNAP/food benefit verification.
- [ ] MEDIUM: Attach official SSDI/SSA benefit letter when available.
- [ ] MEDIUM: Update current bank balances before submitting any means-tested asset disclosure.
- [ ] MEDIUM: Confirm exact Aaron's monthly payment and balance from statement.
- [ ] MEDIUM: Confirm SimpliSafe actual monthly amount ($10 vs $30).
- [ ] MEDIUM: Confirm exact property tax monthly equivalent and any veteran tax credit/abatement options.

## Next Queue (Optional Maintenance)

- [ ] LOW: Push to remote once git credentials are authenticated on the host.
- [ ] LOW: Setup automated CI/CD for distribution if scaling beyond local host.

## Completed

- [x] HIGH: Implemented Ledger & Transactions actual-spending tracker.
- [x] HIGH: Fixed Android APK routing, assets, and VA seed data injection.
- [x] HIGH: Overhauled Mobile UX (Bottom Nav, Transparent Status Bar, Safe Areas).
- [x] HIGH: Cross-platform Packaging (Android APK via Capacitor, Windows .exe config via Electron).
- [x] HIGH: Overhauled UI with "Immersive Deep Glass" aesthetic.
- [x] HIGH: Generate and export VA Assistance Seed Data to `va-assistance-seed.json`.
- [x] HIGH: Tailor meta-system for Budget Beacon (`PROJECT_PROFILE.md`, `ROADMAP.md`, `PLAN.md`, `docs/`).
- [x] HIGH: Project Wrap-up. Git initialized, remote `SavigeSystemZ/BudgetBeacon` added.
- [x] HIGH: Advanced Installer. Built `install.sh` and successfully installed Budget Beacon to `/home/whyte/.local/bin`.
- [x] HIGH: M8 — Final Polish (Dark Mode + PWA).
- [x] HIGH: M7 — Backup + Polish + Hardening.
- [x] HIGH: M6 — Credit Snapshot + Reports.
- [x] HIGH: M5 — Stash Map Forecasting.
- [x] HIGH: M4 — Beacon Dashboard.
- [x] HIGH: M3 — Budget Engine.
- [x] HIGH: M2 — Income + Pay Path + Stash Map Forms.
- [x] HIGH: M1 — Data Model + Local Storage.
- [x] HIGH: M0 — Scaffold Budget Beacon.

## Usage rules
- Keep this file current enough that another tool can pick up immediately.
- Use priority signals so the next agent knows what to work on first.
- Mark items `[x]` only when fully done, not "mostly done."