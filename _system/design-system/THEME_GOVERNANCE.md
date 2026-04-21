# Additive theme and aesthetic governance

**Mission:** Never destroy a working UI aesthetic. Redesigns and visual improvements MUST be implemented as parallel, selectable themes.

## Rules for AI agents

1. **No destructive overwrites:** When asked to "update the design," "change the colors," or "modernize the look," do not overwrite the existing CSS, Tailwind configuration, or theme-provider tokens in place. Preserve the prior state as a named theme.
2. **Theme matrix:** Snapshot the current working design into a discrete, versioned configuration (for example `theme-legacy.json` or a `legacy` entry in `themes.ts`). Implement the new specification as a sibling theme (for example `theme-modern-dark.json`).
3. **Runtime switching:** The application should expose a theme selector (for example `<ThemeSelector />` or framework equivalent) so operators can switch between historical and new aesthetics without redeploying.
4. **Portable abstractions:** Theme data must be portable—prefer CSS variables, Tailwind config presets, or serialized design tokens. Avoid one-off inline styles for systemic colors or spacing.
5. **Validation:** Before completing a UI overhaul, confirm the previous theme remains reachable through the selector and that layout structure has not regressed for core flows.

## Related system docs

- `_system/MODERN_UI_PATTERNS.md` — layout, components, responsive behavior
- `_system/DESIGN_EXCELLENCE_FRAMEWORK.md` — product and interface quality bar
