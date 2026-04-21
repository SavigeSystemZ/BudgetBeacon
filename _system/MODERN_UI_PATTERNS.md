# Modern UI Patterns

Build interfaces that feel native, fast, and intentional on every device.

## Component architecture

- Components are the unit of UI. Each component has a single responsibility.
- Separate presentational components (how things look) from container components (how things work).
- Keep component files focused. One primary export per file.
- Colocate styles, tests, and types with the component they belong to.
- Use composition over configuration. Prefer children and render slots over sprawling prop APIs.
- Limit prop drilling to 2 levels. Beyond that, use context, stores, or dependency injection.
- Design components for reuse by default. Extract layout, spacing, and theming into the design system.

## Layout and responsive design

- Use CSS Grid for page-level and complex two-dimensional layouts.
- Use Flexbox for one-dimensional alignment and distribution.
- Design mobile-first. Start with the narrowest layout and enhance for larger screens.
- Use `clamp()`, `min()`, and `max()` for fluid typography and spacing that scales without breakpoints.
- Define breakpoints based on content needs, not device names. Common ranges: 480px, 768px, 1024px, 1440px.
- Use container queries where supported for truly responsive components that adapt to their container, not the viewport.
- Never use fixed widths for content containers. Use `max-width` with fluid inner spacing.
- Ensure touch targets are at least 44x44px with adequate spacing on mobile.

## Typography

- Establish a type scale based on a consistent ratio (1.25 major third, 1.333 perfect fourth, or 1.5 major fifth).
- Limit to 2-3 font families maximum: one for headings, one for body, optionally one for code.
- Use system font stacks for body text when brand typography is not required: `-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif`.
- Set base font size to 16px minimum. Never go below 14px for body text.
- Use relative units (`rem`, `em`) for font sizes to respect user preferences.
- Line height: 1.4-1.6 for body text, 1.1-1.3 for headings.
- Maximum line width: 65-75 characters for readability.
- Use `font-display: swap` for web fonts to prevent invisible text during loading.

## Color system

- Define a complete color palette with semantic tokens: `--color-primary`, `--color-surface`, `--color-text`, `--color-error`, `--color-success`, `--color-warning`.
- Include a neutral scale with at least 9 steps (50-900) for backgrounds, borders, and text.
- Define light and dark themes using CSS custom properties. Never hardcode colors in components.
- Ensure all color combinations meet WCAG AA contrast ratios (4.5:1 text, 3:1 non-text).
- Use opacity and alpha channels for overlays and hover states, not separate color values.
- Support `prefers-color-scheme` with automatic theme switching and a manual override.
- Test both themes with color blindness simulations.

## Spacing and rhythm

- Use a spacing scale based on a consistent unit (4px or 8px base).
- Define spacing tokens: `--space-xs` (4px), `--space-sm` (8px), `--space-md` (16px), `--space-lg` (24px), `--space-xl` (32px), `--space-2xl` (48px), `--space-3xl` (64px).
- Apply consistent spacing between sections, cards, form fields, and list items.
- Use margin for spacing between siblings. Use padding for internal component space.
- Avoid arbitrary spacing values. Every space value should come from the scale.

## Motion and animation

- Use motion purposefully: to show relationships, provide feedback, and guide attention.
- Keep durations short: 150-300ms for micro-interactions, 300-500ms for page transitions.
- Use appropriate easing: `ease-out` for entrances, `ease-in` for exits, `ease-in-out` for position changes.
- Animate only `transform` and `opacity` for 60fps performance. Avoid animating layout properties.
- Respect `prefers-reduced-motion`. Provide `@media (prefers-reduced-motion: reduce)` overrides that disable or simplify animations.
- Use CSS transitions for simple state changes. Use CSS animations or JS animation libraries for complex sequences.
- Never use animation to delay or obstruct user actions.

## Dark mode

- Implement dark mode from the start, not as an afterthought.
- Do not simply invert colors. Design a separate dark palette with appropriate contrast.
- Dark backgrounds should be desaturated, not pure black. Use `#121212` to `#1a1a2e` range.
- Reduce surface contrast in dark mode. Use elevation (lighter surfaces for higher elements) instead of shadows.
- Adjust image brightness and saturation for dark backgrounds. Use `filter: brightness(0.9)` on photos if needed.
- Test all UI states in both themes: empty, loading, error, success, hover, focus, active, disabled.
- When replacing or overhauling a visual system, follow `_system/design-system/THEME_GOVERNANCE.md`: add new themes in parallel and keep prior themes selectable.

## Icons and imagery

- Use a consistent icon set throughout the application. Do not mix icon families.
- Prefer SVG icons for sharpness, scalability, and color control.
- Use `currentColor` for icon fill so they inherit the text color.
- Provide meaningful alt text for informational images. Use `alt=""` for decorative images.
- Use optimized image formats: WebP or AVIF for photographs, SVG for illustrations and icons, PNG only for raster images requiring transparency.
- Implement responsive images with `srcset` and `sizes` attributes.
- Lazy-load images below the fold.

## Forms

- Group related fields logically with clear section labels.
- Use appropriate input types: `email`, `tel`, `url`, `number`, `date`, `search`.
- Provide inline validation on blur, not on every keystroke.
- Show error messages directly below or beside the relevant field.
- Use clear, specific error messages: "Email must include @ and a domain" not "Invalid input".
- Indicate required fields. Prefer marking optional fields as "(optional)" rather than marking required with asterisks.
- Support autocomplete for standard fields (name, email, address, payment).
- Disable submit buttons during form submission to prevent double submission.
- Provide visible loading state during async validation or submission.

## Loading and empty states

- Show skeleton screens instead of spinners for content-heavy pages.
- Use subtle shimmer or pulse animations on skeletons to indicate progress.
- Design empty states with clear messaging and a call to action: "No projects yet. Create your first project."
- Show progress indicators for operations longer than 1 second.
- Use optimistic updates for actions that are very likely to succeed (toggling, starring, marking as read).
- Provide error recovery actions in error states: "Something went wrong. Try again."

## Navigation patterns

- Use persistent navigation for primary app sections.
- Use breadcrumbs for deep hierarchies.
- Highlight the current location in navigation.
- Support browser back/forward behavior correctly in SPAs.
- Use URL-based routing for all navigable states. Users should be able to bookmark and share URLs.
- Implement command palettes (Cmd+K / Ctrl+K) for power users in complex applications.
- Provide keyboard shortcuts for frequent actions and document them in a discoverable way.

## Navigation deduplication

- **One primary navigation authority per surface** — do not duplicate the same destination in a
  sidebar, top bar, footer, and floating menu on the same view unless each instance serves a clearly
  different audience (e.g. mobile drawer vs desktop rail). Prefer a single menu for a given
  breakpoint.
- **Avoid redundant controls** — if an action appears in a page header, do not repeat the same
  labeled button in a card on the same page unless one is a shortcut with distinct context (e.g.
  empty-state CTA). Remove duplicate “Settings”, “Profile”, or “Home” links that navigate to the
  same route.
- **Command palettes** should complement, not clone, the full nav: expose search and power actions,
  not a second copy of every sidebar item.
- When refactoring, **audit routes** linked from multiple chrome elements and collapse to the
  pattern that matches `_system/DESIGN_EXCELLENCE_FRAMEWORK.md` and the product’s information
  architecture.

## Responsive tables and data

- Use horizontal scrolling for wide tables on narrow screens.
- Consider card-based layouts as an alternative to tables on mobile.
- Provide sticky headers for long scrollable tables.
- Align numbers to the right. Align text to the left. Align dates and status badges consistently.
- Use zebra striping or subtle row dividers for scannability in dense tables.
- Implement column sorting with clear visual indicators.
