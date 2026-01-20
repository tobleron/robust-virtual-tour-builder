# Task: Refactor Sidebar Inline Styles to CSS Classes

## Objective
Move all inline styling logic and `style={makeStyle(...)}` calls from `src/components/Sidebar.res` into external CSS files (`css/components/ui.css` or `css/components/buttons.css`).

## Context
The `Sidebar.res` currently contains branding gradients, font sizes, and specific padding defined in ReScript. This mixes presentation with logic, violating the Separation of Concerns.

## Steps
1. Identify all `style={makeStyle({...})}` occurrences in `src/components/Sidebar.res`.
2. Extract the CSS properties into meaningful class names in `css/components/ui.css`.
3. Replace the `style` props in `Sidebar.res` with the new classes via `className`.
4. Ensure Tailwind classes are still used where appropriate, but complex/custom styling is moved to CSS.

## Verification
- [ ] No regression in the visual appearance of the Sidebar header and branding.
- [ ] Action buttons (`New`, `Save`, `Load`, `About`) maintain their layout and styling.
- [ ] Verify that hover and active states (e.g., `hover-lift`, `active-push`) still function correctly.
- [ ] `npm run build` passes without errors.
