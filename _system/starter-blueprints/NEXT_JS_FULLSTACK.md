# Next.js Fullstack Blueprint

Use this when bootstrapping a Next.js fullstack application (App Router, TypeScript, Tailwind CSS).

## Expected repo shape

```
src/
  app/
    layout.tsx
    page.tsx
    globals.css
    api/
  components/
  lib/
  hooks/
public/
prisma/ (if using Prisma)
package.json
tsconfig.json
next.config.ts
tailwind.config.ts
postcss.config.js
.env.local
```

## Stack signals

- Primary languages: TypeScript
- Primary frameworks: Next.js, React
- Package managers: npm, pnpm, or bun
- Build tools: Next.js (Webpack/Turbopack)
- Runtime environments: Node.js, Edge (for middleware)

## Validation commands

- Lint: `npm run lint` (Next.js includes ESLint config)
- Typecheck: `npx tsc --noEmit`
- Unit tests: `npm run test` (vitest or jest)
- Build: `npm run build`
- Dev: `npm run dev`
- E2E: `npx playwright test` (if configured)

## Quality expectations

- App Router with server components by default. Client components only when interactivity requires it.
- Server actions for form mutations. API routes for external integrations.
- Proper metadata and SEO on every page.
- Image optimization via `next/image`.
- Font optimization via `next/font`.
- Loading, error, and not-found boundaries for each route segment.
- Environment variables validated at build time.
- Middleware for auth guards, redirects, and rate limiting.

## First milestone suggestion

- Confirm dev server starts cleanly.
- Confirm build completes without errors or warnings.
- Confirm lint and typecheck pass.
- Confirm at least one page renders with proper metadata.
- Confirm error and loading boundaries exist for the root layout.
- Set up testing framework and write first smoke test.
