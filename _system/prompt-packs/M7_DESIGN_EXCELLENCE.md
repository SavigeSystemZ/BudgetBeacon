# M7 Design Excellence Prompt Pack

## M7.0 Design direction

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Read the design framework and propose a high-quality UI direction for the touched surface.

Read:
- _system/DESIGN_EXCELLENCE_FRAMEWORK.md
- _system/MODERN_UI_PATTERNS.md
- _system/design-system/THEME_GOVERNANCE.md
- _system/ACCESSIBILITY_STANDARDS.md
- _system/PROJECT_PROFILE.md (experience targets section)

Deliver:
1. Layout hierarchy — define the primary action, content reading order, and section grouping for each view. Use whitespace deliberately: group related elements tightly, separate unrelated sections clearly.
2. Component patterns — identify the UI components needed (cards, forms, tables, modals, navigation). Each component type must be used consistently everywhere it appears.
3. Visual direction — define the color palette (primary, secondary, semantic colors for success/warning/error/info), typography scale (headings, body, captions with consistent step ratio), and spacing system (base unit and multipliers).
4. State coverage plan — for every view, define how it looks in: empty (first-use guidance), loading (skeleton or spinner), error (helpful message with recovery action), success (confirmation), and edge (long text, zero results, maximum results).
5. Responsive strategy — define how layout adapts at mobile (< 640px), tablet (640–1024px), and desktop (> 1024px). Navigation pattern for each (drawer, bottom bar, sidebar).
6. Interaction model — define feedback patterns: button press (100ms visual response), form submission (loading indicator, success/error state), navigation (transition style), and data mutation (optimistic or confirmed).
7. Validation criteria — what must be true for the design to be considered complete: contrast ratios met, all states implemented, responsive at 3 breakpoints, touch targets ≥ 44px, body text ≥ 16px.
```

## M7.1 Design implementation

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Implement the touched UI with deliberate hierarchy, responsive behavior, and designed states.

Read:
- _system/DESIGN_EXCELLENCE_FRAMEWORK.md
- _system/MODERN_UI_PATTERNS.md
- _system/design-system/THEME_GOVERNANCE.md
- _system/ACCESSIBILITY_STANDARDS.md
- DESIGN_NOTES.md (if direction was established in M7.0)

Constraints:
- No generic placeholder UI. Every element must look intentional.
- No browser-default styled elements in a designed interface (unstyled buttons, raw inputs, default checkboxes).
- Preserve existing design systems when present. Extend, don't replace.
- Cover empty, loading, error, and success states for every interactive view.
- Touch targets ≥ 44x44px. Body text ≥ 16px. Line height 1.4–1.6.
- Text contrast ≥ 4.5:1 (normal text) or ≥ 3:1 (large text / UI components).
- Respect prefers-reduced-motion and prefers-color-scheme media queries.
- Use semantic HTML elements (nav, main, section, article, header, footer, button, label).
- Animations serve orientation (page transitions, element entrances), not decoration. 150–300ms for micro-interactions.

Deliver:
1. Implemented components with all required states.
2. Responsive layout verified at mobile, tablet, and desktop.
3. Accessibility basics: keyboard navigation, focus management, screen reader labels.
4. Updated DESIGN_NOTES.md with component patterns and decisions made.
5. Updated WHERE_LEFT_OFF.md with design work completed and remaining surfaces.
```

## M7.2 Design review

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Review the current UI against the design quality bar.

Read:
- _system/DESIGN_EXCELLENCE_FRAMEWORK.md
- _system/MODERN_UI_PATTERNS.md
- _system/review-playbooks/UI_UX_REVIEW_PLAYBOOK.md

For each view or component in scope, evaluate:
1. Hierarchy: Is there one clear primary action? Does size/weight/color guide the eye?
2. Consistency: Are the same patterns used for the same purpose everywhere?
3. States: Empty, loading, error, success, edge — all present?
4. Responsiveness: Does the layout work at 360px, 768px, and 1280px?
5. Contrast: All text meets WCAG AA?
6. Typography: Intentional scale, readable line length (45–75 chars), adequate line height?
7. Feedback: Every action produces visible response within 100ms?
8. Motion: Animations serve purpose, respect prefers-reduced-motion?

Output:
- Must-fix: broken layouts, missing states, contrast failures, inaccessible controls.
- Should-fix: inconsistent patterns, weak hierarchy, missing feedback.
- Polish: spacing refinement, animation tuning, typographic cleanup.
```
