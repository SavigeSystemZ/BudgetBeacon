---
name: accessibility-review
description: Audit UI changes for accessibility compliance against WCAG 2.2 AA standards
---

# Accessibility Review Skill

## Authority

- `AGENTS.md`
- `_system/ACCESSIBILITY_STANDARDS.md`
- `_system/review-playbooks/ACCESSIBILITY_REVIEW_PLAYBOOK.md`
- `_system/PROJECT_PROFILE.md`

## Steps

1. Read `_system/ACCESSIBILITY_STANDARDS.md` and the accessibility review playbook.
2. Identify the changed or in-scope UI components.
3. Check against each review category:
   - Semantic HTML and landmark usage
   - Keyboard navigation and focus management
   - ARIA attributes and screen reader experience
   - Color contrast (4.5:1 text, 3:1 non-text)
   - Touch target sizes (44x44px minimum)
   - Form labeling and error announcement
   - Motion and prefers-reduced-motion support
   - Zoom and reflow at 200% and 400%
4. Classify findings as must-fix, should-fix, or optional.
5. Report using the playbook output format.
6. Record unresolved items in `FIXME.md`.
7. Update `WHERE_LEFT_OFF.md` if the review surfaces significant work.
