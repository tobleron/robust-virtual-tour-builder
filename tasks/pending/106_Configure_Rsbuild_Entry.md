# Task: Configure Rsbuild HTML & Entry Point
**Priority:** High
**Status:** Pending

## Objective
Connect your existing `index.html` and ReScript output (`.bs.js`) to Rsbuild so the application renders correctly in the browser.

## Context
Rsbuild needs to know where your HTML template is and which JavaScript file kicks off the React app.

## Requirements
1.  **Analyze** `index.html`. It currently likely imports `src/Main.bs.js`.
2.  **Configure** `rsbuild.config.mjs`:
    *   Ensure `html.template` points to `./index.html`.
    *   Ensure `source.entry` includes the correct entry point (likely `./src/Main.bs.js` if that's what `index.html` uses).
3.  **Verify Asset Loading**: Ensure `public/` assets (images, css) are correctly served by Rsbuild's dev server.
4.  **Test HMR**: Run `npm run rsbuild:dev`, make a small change in a `.res` file (wait for ReScript to compile), and verify if Rsbuild refreshes the browser automatically.

## Verification
*   App loads at `http://localhost:3000` (or Rsbuild default port).
*   Backend API calls work (proxy active).
*   Styles (Tailwind) are applied (might need to ensure Tailwind CLI output is being watched or integrated).
