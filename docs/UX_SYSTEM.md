# UX & Design System

## Visual Direction
Budget Beacon should feel:
- Calm, modern, slightly premium.
- Clear and practical, prioritizing readability.
- Avoiding cartoonish elements or corporate-boring enterprise layouts.
- Styled using Tailwind CSS v4 and `shadcn/ui`.

## Layout Structure
1. **Top Bar:** App title, optional month selector.
2. **Main KPI Row:** Monthly Income, Pay Path Required, Stash Map Scheduled, Leftover.
3. **Middle Section:** Allocation Donut Chart, Cash Flow Status, Pay Path Timeline.
4. **Bottom Section:** Deterministic Recommendations, Stash Map Progress, Credit Snapshot summary.

## Empty States
- **Pay Path:** "Add your first bill or debt so Budget Beacon can map what must be paid."
- **Stash Map:** "Create your first savings goal to see how long it will take and whether your monthly plan is realistic."

## Accessibility (A11y)
- Form controls must have proper labels.
- Error states must be text-based, not color-only.
- Charts must include semantic text summaries.
- Keyboard navigation must work across the app.
- Destructive buttons must prompt clear confirmation dialogs.