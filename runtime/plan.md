# Budget Beacon — Final Polish Plan

## Objective
The core MVP functionality is fully implemented. The objective of this final phase is to enhance the user experience (UX) and native feel of Budget Beacon by adding a Dark Mode toggle and Progressive Web App (PWA) support.

## Scope of Work

1. **Dark Mode Integration:**
   - Create a `ThemeProvider` context in `src/components/theme-provider.tsx` to manage the `dark` class on the root HTML element.
   - Create a `ModeToggle` component using `lucide-react` icons (Sun/Moon).
   - Integrate the `ModeToggle` into the `AppShell` sidebar navigation so users can easily switch themes.

2. **Progressive Web App (PWA):**
   - Install `vite-plugin-pwa` as a dev dependency.
   - Configure `vite.config.ts` to generate a Web App Manifest and Service Worker. This will allow users to "Install" the Budget Beacon application directly to their home screen or desktop, ensuring a snappy, offline-first native feel.
   - Update `index.html` with basic meta tags for theme color and PWA compatibility.

3. **Final Polish:**
   - Ensure the UI looks consistent in both Light and Dark themes (Tailwind `dark:` variants are already configured in `index.css`).

## Execution Steps
1. Write the new components (`theme-provider.tsx`, `mode-toggle.tsx`).
2. Update `App.tsx` and `AppShell` layout.
3. Install PWA dependencies and modify `vite.config.ts`.
4. Run a final build and lint check to verify completion.