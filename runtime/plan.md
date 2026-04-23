# Mobile UX Polish & Navigation Overhaul

## Background & Motivation
The user noted that when they launched the APK, they were stuck on a single page with no menus or options, and the graphics were lacking. This was due to two major bugs:
1. The deep glass styles for `App.tsx` were accidentally reverted during a previous merge conflict fix.
2. The navigation sidebar was hidden on mobile devices (`md:hidden`), but no mobile-specific navigation menu (like a hamburger or bottom nav) was implemented.

To make the app truly perfect and complete on Android, we must add a mobile-native navigation paradigm and restore the immersive deep glass effects.

## Scope & Impact
- **In Scope**: Rewriting `src/App.tsx` to include a persistent, app-like **Bottom Navigation Bar** for mobile screens.
- **In Scope**: Restoring the "Deep Glass" transparent backgrounds and frosted sidebar styles to the App Shell.
- **In Scope**: Adding the missing `<Route path="/ledger" />` back into the router.
- **In Scope**: Updating global CSS (`src/index.css`) to respect `env(safe-area-inset-*)` so the app doesn't underlap behind Android notches/status bars.
- **Out of Scope**: Changing existing route components (they are already responsive).

## Proposed Solution
1. **AppShell Redesign**: I will refactor `AppShell` in `src/App.tsx`. 
   - On desktop (`md:flex`), it will use the frosted glass sidebar.
   - On mobile (`md:hidden`), it will feature a fixed Bottom Navigation Bar, built with `lucide-react` icons and a frosted glass (`backdrop-blur-xl`) aesthetic.
2. **Safe Areas**: I will add `padding-bottom: env(safe-area-inset-bottom)` to the bottom nav and `padding-top: env(safe-area-inset-top)` to the main view to prevent Android OS system UI overlapping.
3. **Capacitor Configuration**: I will install `@capacitor/status-bar` to make the Android status bar transparent, allowing the deep glass gradient to bleed into the system tray beautifully.

## Implementation Plan
1. **Phase 1: Capacitor Plugins**: Install the Capacitor status bar plugin and sync.
2. **Phase 2: Safe Areas & CSS**: Update `src/index.css` for safe area handling.
3. **Phase 3: AppShell & Mobile Nav**: Rewrite `src/App.tsx` completely to include the Bottom Navigation component with `lucide-react` icons (LayoutDashboard, Wallet, CreditCard, PiggyBank, Receipt, Settings).
4. **Phase 4: Re-package**: Rebuild the Vite app and re-assemble the final Android APK.

## Verification
- Verify the mobile bottom nav appears when shrinking the browser window.
- Verify clicking bottom nav icons changes the route correctly.
- Verify the Android APK builds successfully.