# Task: Refactor ViewerUI Inline Styles to CSS Classes

## Objective
Move inline styling and hardcoded style definitions in `src/components/ViewerUI.res` to external CSS classes in `css/components/viewer.css` or `css/components/ui.css`.

## Context
The `ViewerUI.res` manage many floating elements (Utility bar, HUD labels, Floor navigation). Many of these have colors and font sizes defined in ReScript logic rather than CSS.

## Steps
1. Audit `src/components/ViewerUI.res` for all `style` attributes.
2. Focus on:
    - Utility buttons (Add Link, Auto-Pilot, Category).
    - HUD Labels (Persistent scene labels).
    - Quality badges (Blurry, Dark, etc.).
    - Linking hints.
3. Move these styles to CSS classes. Use state-based sub-classes where needed.
4. Replace inline styles with `className`.

## Verification
- [ ] Utility bar buttons correctly reflect active state (e.g., Linking mode ACTIVE turns yellow).
- [ ] HUD labels appear correctly positioned and styled.
- [ ] Quality badges show the correct background colors based on severity.
- [ ] No regression in Viewer layout or interactivity.
- [ ] `npm run build` verification.
