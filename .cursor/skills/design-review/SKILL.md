---
name: design-review
description: Review touched UI or product surfaces for hierarchy, coherence, polish, and quality.
---

# Design Review

## Authority

1. `_system/DESIGN_EXCELLENCE_FRAMEWORK.md`
2. `_system/MODERN_UI_PATTERNS.md`
3. `_system/review-playbooks/UI_UX_REVIEW_PLAYBOOK.md`
4. `_system/PROJECT_PROFILE.md`

## Review methodology

### 1. Visual hierarchy

Every screen must have a clear reading order:

- **Primary action**: One dominant CTA per view, visually distinct (size, color, weight).
- **Secondary actions**: Clearly subordinate — smaller, outlined, or text-only.
- **Content hierarchy**: Headings establish structure. Body text is readable. Metadata is deemphasized.
- **Whitespace**: Generous spacing between sections. Related items grouped tightly. Unrelated items separated clearly.

Flag: competing CTAs at equal weight, walls of undifferentiated text, cramped layouts with no breathing room, orphaned elements with no visual grouping.

### 2. Component quality

- **Consistency**: Same pattern for same purpose everywhere (cards, lists, buttons, forms).
- **States**: Every interactive component must handle default, hover, focus, active, disabled, loading, error, and empty states.
- **Feedback**: Every user action produces visible feedback within 100ms (button press, form submission, navigation).
- **Sizing**: Touch targets at least 44x44px. Text at least 16px for body copy. Line height 1.4–1.6.

Flag: unstyled native elements, inconsistent button styles, missing loading/error states, tiny click targets.

### 3. Layout and responsiveness

- **Grid alignment**: Content aligns to a consistent grid or spacing system.
- **Breakpoints**: Layout adapts meaningfully at mobile (< 640px), tablet (640–1024px), and desktop (> 1024px).
- **Overflow**: No horizontal scrolling on any viewport. Text wraps. Images scale. Tables scroll within their container.
- **Navigation**: Primary nav is accessible on all viewports. Mobile gets a drawer or bottom bar, not just a shrunken desktop nav.

Flag: broken layouts at common viewport sizes, content wider than viewport, navigation hidden on mobile.

### 4. Color and contrast

- **Contrast**: Text meets WCAG AA (4.5:1 for normal text, 3:1 for large text and UI components).
- **Intentional palette**: Colors are deliberate, not random. Semantic colors for success, warning, error, info.
- **Dark mode**: If supported, verify contrast and legibility in both themes.

Flag: low-contrast text, inconsistent color usage, hardcoded colors instead of design tokens.

### 5. Typography

- **Font stack**: Intentional font choices, not browser defaults.
- **Scale**: Clear typographic scale (headings, body, captions, labels) with consistent step ratio.
- **Readability**: Line length 45–75 characters for body text. Adequate line height. No justified text on the web.

Flag: more than 2–3 font families, inconsistent heading sizes, lines of text wider than 80 characters.

### 6. State coverage

Every view must show appropriate states:

- **Empty**: First-use experience with guidance, not a blank page.
- **Loading**: Skeleton screens or spinners, not frozen UI.
- **Error**: Helpful error messages with recovery actions, not raw stack traces.
- **Success**: Confirmation of completed actions.
- **Edge**: Long text, missing images, zero results, maximum results.

Flag: blank empty states, uncaught error pages, success without confirmation feedback.

### 7. Motion and transitions

- **Purpose**: Animation should orient the user (page transitions, element entrances), not decorate.
- **Duration**: 150–300ms for micro-interactions, 300–500ms for layout transitions.
- **Reduced motion**: Respect `prefers-reduced-motion` media query.

Flag: janky animations, excessive decorative motion, no reduced-motion support.

## Output format

For each finding, report:

- **Severity**: must-fix / should-fix / polish
- **Location**: component, page, or flow
- **Finding**: what the issue is
- **Standard**: which quality criterion it violates
- **Fix**: specific corrective action

## Output

- must-fix quality issues (hierarchy, contrast, missing states, broken layouts)
- usability risks (confusing flows, missing feedback, accessibility gaps)
- polish opportunities (spacing refinement, animation improvement, consistency cleanup)
