# Accessibility Review Playbook

## Review inputs

- changed files
- `_system/ACCESSIBILITY_STANDARDS.md`
- `_system/PROJECT_PROFILE.md` (experience targets section)

## Review for

1. **Semantic structure**: Are native HTML elements used correctly? Are landmarks, headings, and lists in logical order?
2. **Keyboard access**: Can every interactive element be reached and operated via keyboard? Is focus order logical? Are focus indicators visible?
3. **Screen reader experience**: Do elements have accessible names? Are dynamic updates announced via aria-live? Is state communicated (expanded, selected, checked)?
4. **Color and contrast**: Do all text and non-text elements meet WCAG AA contrast ratios? Is color ever the sole indicator of meaning?
5. **Touch targets**: Are interactive elements at least 44x44px with adequate spacing?
6. **Forms**: Does every input have an associated label? Are errors specific, adjacent, and announced?
7. **Media**: Do images have appropriate alt text? Is video captioned? Is auto-play controllable?
8. **Motion**: Are animations respectful of `prefers-reduced-motion`? Is essential content accessible without animation?
9. **Zoom and reflow**: Does the layout work at 200% and 400% zoom without horizontal scrolling for main content?

## Must-fix findings

- Interactive elements unreachable by keyboard.
- Missing accessible names on buttons, links, or inputs.
- Contrast ratios below WCAG AA minimums.
- Focus traps that cannot be escaped.
- Form inputs without associated labels.
- Dynamic content changes not announced to screen readers.
- Color as the sole indicator of state or meaning.

## Output format

```
## Accessibility Review

### Must-fix
- [ ] finding (file:line)

### Should-fix
- [ ] finding (file:line)

### Verified
- keyboard navigation: pass/fail
- screen reader announcement: pass/fail
- contrast ratios: pass/fail
- focus management: pass/fail
- semantic structure: pass/fail
```
