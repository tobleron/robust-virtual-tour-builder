# Task: Migrate Conditional Styling Logic to CSS Classes

## Objective
Convert state-dependent conditional styling logic in ReScript (e.g., `backgroundColor: if condition { colorA } else { colorB }`) into CSS class toggling.

## Context
Currently, the "Linking Mode" toggle or "Auto-Pilot" status changes button colors by calculating hex codes in ReScript. This logic belongs in CSS using state classes like `.is-active` or `.is-linking`.

## Steps
1. Identify components where background colors or visibility depend on state variables.
2. Define corresponding CSS classes in relevant stylesheets (e.g., `.floating-btn--active`).
3. Update the ReScript `className` logic to toggle these classes.
4. Remove the `style` logic that was handling these transitions.

## Verification
- [ ] Toggle "Linking Mode" (FAB button): Verify color transitions smoothly from red (+) to yellow (×).
- [ ] Toggle "Auto-Pilot": Verify the play/stop button changes color and pulse animation correctly.
- [ ] Verify "Category Toggle" updates appearance (Indoor/Outdoor icons and background colors).
- [ ] `npm run build` verification.
