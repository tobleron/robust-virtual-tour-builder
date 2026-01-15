# Task: Integrate Tailwind with Rsbuild
**Priority:** Medium
**Status:** Pending

## Objective
Replace the separate `tailwindcss` watcher with Rsbuild's internal CSS processing (via PostCSS) for a unified build pipeline.

## Context
Currently, `npm run css:watch` runs separately. Rsbuild can handle Tailwind directly, meaning one less terminal window to manage.

## Requirements
1.  **Install** `postcss` and `tailwindcss` (if not already installed as deps, likely are).
2.  **Verify** `postcss.config.js` exists (or create it with tailwindcss plugin).
3.  **Import** your main CSS file (e.g., `src/index.css` or wherever Tailwind directives are) into your **Entry JS file** (`Main.bs.js` or a new `index.js` wrapper).
    *   *Note:* Since `Main.bs.js` is generated, you might need to create a small `src/index.js` that imports the CSS and then imports `Main.bs.js`, and set *that* as the Rsbuild entry.
4.  **Remove** the `<link href="/css/style.css">` from `index.html` (Rsbuild will inject it).

## Verification
*   `npm run rsbuild:dev` builds both JS and CSS.
*   Changing a Tailwind class in a `.res` file (which compiles to `.js`) triggers an HMR update with the new style.
