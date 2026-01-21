# Task 274 Report: Migrate Conditional Styling to Classes

## Objective
Convert state-dependent conditional styling logic in ReScript into CSS class toggling and centralize styling tokens.

## Changes Implemented

### 1. Refactored `src/components/ViewerUI.res`
- Replaced inline conditional Tailwind classes (e.g., `simActive ? "opacity-40 pointer-events-none" : ...`) with semantic CSS classes (`state-disabled`).
- Removed `hover:bg-primary-light` from explicit `className` construction to allow CSS-controlled semantic hover states.
- Ensured consistent usage of `state-idle`, `state-linking`, `state-active`, `cat-outdoor` (etc.) classes.

### 2. Updated `css/components/viewer.css`
- **Token Migration**: Replaced all hardcoded hex values with CSS variables from `variables.css` (e.g., `#dc3545` -> `var(--danger)`, `#ffcc00` -> `var(--accent)`).
- **Semantic Hover States**: Added specific `:hover` rules for each state (e.g., `.state-idle:hover` uses `var(--danger-light)`).
- **New Classes**: Added `.v-util-btn.state-disabled` to handle disable logic centrally.

## Verification
- [x] `npm run build` passed successfully.
- [x] Verified `ViewerUI.res` no longer contains ad-hoc opacity logic for these buttons.
- [x] Verified `viewer.css` uses `var(--...)` tokens for all modified classes.
- [x] Verified hover states are now governed by CSS based on the button's semantic state.
