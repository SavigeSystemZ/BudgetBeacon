# React Vite TypeScript Blueprint

Use this for greenfield product surfaces that need fast iteration, modern TypeScript defaults, and polished frontend behavior.

## Expected repo shape

```
src/
  components/     reusable UI pieces
  routes/         page-level surfaces (or screens/)
  hooks/          custom React hooks
  lib/            utilities and helpers
  styles/         global styles (or co-located CSS)
  assets/         images, icons, fonts
public/           truly static assets only
tests/            test files (or co-located with src/)
index.html
package.json
tsconfig.json
vite.config.ts
```

## Baseline stack

- React 18+
- TypeScript (strict mode)
- Vite
- ESLint + Prettier (recommended)
- Vitest or Jest for testing

## Validation commands

- Lint: `npm run lint`
- Typecheck: `npx tsc --noEmit`
- Unit tests: `npm run test`
- Build: `npm run build`
- Dev: `npm run dev`
- Format: `npm run format` (if configured)

## Quality expectations

- Strong visual hierarchy from the first screen — one clear primary action, intentional typography scale, deliberate spacing.
- Designed empty, loading, and error states for every interactive view. No blank pages or raw error dumps.
- Responsive layout behavior from the first milestone — works at mobile, tablet, and desktop.
- Component consistency — same pattern for same purpose everywhere.
- Semantic HTML elements (nav, main, section, button, label). Not divs for everything.
- Avoid generic component soup — every UI element should look intentional.
- Touch targets at least 44x44px. Body text at least 16px.
- Text contrast meets WCAG AA (4.5:1 for normal text).

## First milestone suggestion

1. Ship one polished happy-path screen with real content (not lorem ipsum).
2. Confirm `npm run build` completes without errors or warnings.
3. Confirm `npx tsc --noEmit` passes with zero type errors.
4. Confirm dev server starts and the page renders correctly at 360px, 768px, and 1280px viewports.
5. Record design decisions, component patterns, and color/type choices in `DESIGN_NOTES.md`.
