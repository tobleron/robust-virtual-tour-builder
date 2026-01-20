# Task: Centralize ReScript Styling Tokens to CSS Variables

## Objective
Eliminate hardcoded hex color codes and dimension constants from ReScript components and replace them with CSS variable references (`var(--...)`).

## Context
Various components use hex codes like `#003da5` (Remax Blue) or `#dc3545` (Remax Red) directly. These should refer to the design tokens defined in `css/variables.css`.

## Steps
1. Search for all hex color codes in `src/**/*.res`.
2. Map these colors to existing variables in `css/variables.css`.
3. If a variable doesn't exist for a repeated color, add it to `css/variables.css`.
4. Update ReScript code to use `var(--variable-name)` via `makeStyle` (if still needed) or move to CSS classes.

## Verification
- [ ] Visual consistency: The colors should remain identical to the user.
- [ ] Themeability test: Change `--primary` in `css/variables.css` and verify that ALL blue elements (buttons, headers, highlights) update simultaneously.
- [ ] `npm run build` verification.
Line 1: # Task: Centralize ReScript Styling Tokens to CSS Variables
