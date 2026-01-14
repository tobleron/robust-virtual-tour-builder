# Task: Finalize Rsbuild Production Build
**Priority:** High
**Status:** Pending

## Objective
Configure the production build command to generate optimized, bundled assets for deployment.

## Context
We need to ensure `npm run build` produces a ready-to-deploy `dist/` folder that the Rust backend can serve.

## Requirements
1.  **Update** `package.json` scripts:
    *   Rename old `build` to `build:legacy`.
    *   Set `build` to `npm run res:build && rsbuild build`.
2.  **Configure** `rsbuild.config.mjs` output:
    *   Set `output.distPath` to a folder the Backend expects (or update Backend to serve from `dist/` instead of root).
    *   *Correction:* The backend currently serves files directly from root. We might need to adjust the backend to serve `dist/index.html` on the root route, OR configure Rsbuild to output to a specific structure.
    *   *Safest Path:* Output to `dist/`. Update `backend/src/main.rs` to serve static files from `../dist` instead of `..`.
3.  **Verify**: Run `npm run build` and check the `dist/` folder size and structure.

## Verification
*   `dist/index.html` exists.
*   JS/CSS files are hashed (e.g., `static/js/index.a1b2.js`).
*   Running the backend pointing to `dist` works.
