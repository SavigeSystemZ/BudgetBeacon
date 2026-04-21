# Design Excellence Framework

Use this document to keep the operating system capable of producing not only working software, but also intentional, high-quality product experiences.

For where this framework sits relative to validation, mobile, and theme governance, see `_system/SYSTEM_ORCHESTRATION_GUIDE.md` (expansion and optimization sections).

## Design north stars

- clarity under real use
- strong visual intent
- coherent information hierarchy
- elegant defaults
- graceful degraded states
- high trust through polish and consistency

## Universal design rules

- Avoid generic, interchangeable UI.
- Every screen should have a clear purpose and hierarchy.
- Empty, loading, error, and offline states must feel designed, not forgotten.
- Use typography, spacing, color, and motion intentionally; never as decoration without function.
- Dense interfaces must remain scannable; simple interfaces must remain purposeful.

## Product categories

### Greenfield premium app

- Build a distinct visual language early.
- Define layout rhythm, typography, color system, and interaction tone before feature sprawl.

### Existing design-system repo

- Preserve and extend the existing visual language instead of imposing a new one.

### Data-dense professional tool

- Prioritize scanning, wayfinding, state clarity, and keyboard/operator flow.
- Avoid decorative clutter that slows the operator.

### Internal tool

- Still require clarity, structure, and trustworthiness.
- Functional does not excuse chaotic or low-signal UI.

## Done criteria for UI work

- primary workflow is obvious
- state changes are understandable
- spacing and alignment feel intentional
- empty/loading/error states are covered
- responsive behavior is acceptable on target layouts
- no obviously generic or accidental-looking surfaces remain in touched areas

## Modern design expectations

### Color and theming

- Define a semantic color system using CSS custom properties.
- Support light and dark themes from the start. Honor `prefers-color-scheme`.
- Ensure all combinations meet WCAG AA contrast ratios.
- Use a neutral scale for backgrounds and borders. Use accent colors sparingly and with purpose.

### Typography and spacing

- Use a type scale with consistent ratios. Never use arbitrary font sizes.
- Base font size: 16px minimum. Line height: 1.4-1.6 for body.
- Use a spacing scale (4px or 8px base). Every margin and padding comes from the scale.
- Maximum content width: 65-75 characters for readability.

### Motion and interaction

- Use motion to show relationships and provide feedback, not as decoration.
- Keep durations short: 150-300ms for micro-interactions.
- Animate only `transform` and `opacity` for 60fps performance.
- Always respect `prefers-reduced-motion`.
- Interactive elements must have visible hover, focus, and active states.

### Responsive and adaptive

- Design mobile-first. Enhance for larger screens.
- Use CSS Grid and Flexbox, not absolute positioning or floats.
- Fluid typography with `clamp()` for seamless scaling.
- Touch targets: 44x44px minimum with adequate spacing.
- Test at common breakpoints: 375px, 768px, 1024px, 1440px.

### State communication

- Loading: use skeleton screens for content, spinners for actions.
- Error: provide clear messaging with recovery actions.
- Empty: design intentional empty states with guidance and next steps.
- Success: provide confirmation feedback without blocking the user.
- Disabled: visually distinct with clear reason communicated via tooltip or adjacent text.

### Layout patterns

- Use consistent page layouts with clear content hierarchy.
- Persistent navigation for primary sections.
- Breadcrumbs for deep content hierarchies.
- Sticky headers and footers where they improve usability.
- Card-based layouts for scannable collections.

## Anti-patterns

- Placeholder aesthetics that were never replaced with intentional design.
- Flat design with no hierarchy or visual weight differentiation.
- Over-animated but low-information UI.
- Unreadable dense dashboards with no visual rhythm.
- Inconsistent interaction patterns across related surfaces.
- Generic Bootstrap or Material defaults with no customization.
- Walls of text with no typographic structure.
- Modal overuse for content that should be inline.
- Infinite scroll without alternative navigation or progress indication.
- Custom scrollbars that break native scrolling behavior.
