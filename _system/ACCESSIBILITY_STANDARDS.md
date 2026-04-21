# Accessibility Standards

Accessibility is not optional. It is a quality requirement on the same level as security and performance.

## Target conformance

- WCAG 2.2 Level AA as the minimum for all user-facing surfaces.
- Level AAA for text contrast and target size where practical.
- Test with real assistive technology, not just automated scanners.

## Semantic HTML

- Use native HTML elements for their intended purpose. A `<button>` is a button, not a styled `<div>`.
- Use landmark elements: `<header>`, `<nav>`, `<main>`, `<aside>`, `<footer>`, `<section>`, `<article>`.
- Use heading levels (`<h1>` through `<h6>`) in logical order. Never skip levels for styling.
- Use `<ul>`, `<ol>`, `<dl>` for lists. Use `<table>` for tabular data with `<th>`, `<caption>`, and `scope` attributes.
- Use `<label>` elements associated with every form input via `for`/`id` or nesting.
- Use `<fieldset>` and `<legend>` to group related form controls.

## ARIA

- First rule of ARIA: do not use ARIA if a native HTML element provides the same semantics.
- Use `aria-label` or `aria-labelledby` for elements that need accessible names but have no visible label.
- Use `aria-describedby` for supplementary descriptions (error messages, help text).
- Use `aria-live` regions for dynamic content updates (toast notifications, chat messages, status changes).
- Use `aria-expanded`, `aria-selected`, `aria-checked`, and `aria-pressed` for stateful controls.
- Use `role` only when no native element matches. Prefer `role="alert"`, `role="dialog"`, `role="tablist"`, `role="menu"` with correct keyboard patterns.
- Never use `aria-hidden="true"` on focusable elements.

## Keyboard navigation

- Every interactive element must be reachable and operable via keyboard alone.
- Tab order must follow the visual reading order. Avoid positive `tabindex` values; use 0 or -1.
- Implement standard keyboard patterns for custom widgets: arrow keys for menus and tabs, Escape to close modals, Enter or Space to activate buttons.
- Focus must be visible. Never remove the default focus indicator without providing a custom one that meets contrast requirements.
- Trap focus inside modals and dialogs. Return focus to the trigger element on close.
- Provide skip-to-content links for keyboard users to bypass repetitive navigation.

## Color and contrast

- Text contrast ratio: minimum 4.5:1 for normal text, 3:1 for large text (18px+ or 14px+ bold).
- Non-text contrast: minimum 3:1 for UI components and graphical objects (icons, borders, focus indicators).
- Never use color alone to convey meaning. Supplement with icons, patterns, text labels, or underlines.
- Test against color blindness simulations (protanopia, deuteranopia, tritanopia).
- Support `prefers-color-scheme` for dark mode. Ensure all contrast ratios hold in both themes.

## Touch and pointer

- Minimum touch target size: 44x44 CSS pixels (WCAG 2.2 Level AA).
- Provide adequate spacing between adjacent targets to prevent accidental activation.
- Support both click and touch events. Do not rely on hover for essential interactions.
- Drag-and-drop must have a keyboard alternative.

## Media

- Provide captions for all video content.
- Provide transcripts for audio content.
- Provide alt text for all meaningful images. Use `alt=""` for decorative images.
- Ensure auto-playing media can be paused and has no audio by default.
- Respect `prefers-reduced-motion`. Disable or reduce animations and transitions for users who request it.

## Forms and validation

- Associate every input with a visible label. Placeholder text is not a label.
- Provide clear, specific error messages adjacent to the field that caused the error.
- Use `aria-invalid="true"` and `aria-describedby` pointing to error messages for invalid fields.
- Do not rely solely on color to indicate errors. Use text, icons, or border changes.
- Support autocomplete attributes for common fields (name, email, address, credit card).
- Allow sufficient time for form completion. Warn before session timeouts.

## Dynamic content

- Announce content changes to screen readers using `aria-live` regions.
- Manage focus when content appears or disappears (modals, drawers, inline expansions).
- Provide loading states that are announced to assistive technology.
- Ensure route changes in SPAs announce the new page title or heading.
- Toast notifications must be announced via `aria-live="polite"` or `role="status"`.

## Testing requirements

- Run axe-core or equivalent in CI for every page or component.
- Test with a screen reader (VoiceOver, NVDA, or JAWS) for critical flows.
- Test with keyboard-only navigation for all interactive paths.
- Test with browser zoom at 200% and 400%.
- Test with high contrast mode enabled.
- Test with `prefers-reduced-motion: reduce` active.
- Include accessibility acceptance criteria in feature specs.

## Common anti-patterns

- Using `div` or `span` as interactive elements without role, tabindex, and keyboard handling.
- Removing focus outlines without replacement.
- Using `title` attribute as the only accessible name.
- Placeholder-only inputs with no associated label.
- Auto-advancing carousels with no pause control.
- Infinite scroll with no alternative navigation or keyboard escape.
- Custom dropdowns that do not implement combobox or listbox keyboard patterns.
- Modal dialogs that do not trap focus or restore focus on close.
