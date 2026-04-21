Review the touched UI or product surface against:

1. `_system/DESIGN_EXCELLENCE_FRAMEWORK.md`
2. `_system/MODERN_UI_PATTERNS.md`
3. `_system/ACCESSIBILITY_STANDARDS.md`
4. `_system/review-playbooks/UI_UX_REVIEW_PLAYBOOK.md`
5. `_system/PROJECT_PROFILE.md`

Evaluate each touched surface for:

1. **Hierarchy**: Is there one clear primary action per view? Does the reading order guide the eye through size, weight, and color?
2. **States**: Does every interactive element handle empty, loading, error, success, and edge states?
3. **Consistency**: Are component patterns (buttons, cards, forms, lists) used consistently across the interface?
4. **Responsiveness**: Does the layout adapt meaningfully at mobile, tablet, and desktop? No horizontal overflow?
5. **Contrast**: Does all text meet WCAG AA contrast (4.5:1 normal, 3:1 large)?
6. **Typography**: Is there an intentional type scale? Is body text 16px+? Line length 45–75 characters?
7. **Feedback**: Does every user action produce visible feedback within 100ms?

Generic, accidental-looking, or browser-default UI in a designed interface is a defect.

Output must-fix design issues first (broken layouts, missing states, contrast failures), then usability risks, then polish opportunities.
