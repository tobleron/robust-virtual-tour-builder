# Task: Install Rsbuild Dependencies & Init Config
**Priority:** High
**Status:** Pending

## Objective
Install Rsbuild and its React plugin, and create the initial configuration file without modifying existing build scripts yet.

## Context
We are migrating from a manual build setup to Rsbuild (Rust-based bundler). This first step sets up the foundation.

## Requirements
1.  **Install** `dev` dependencies:
    *   `@rsbuild/core`
    *   `@rsbuild/plugin-react`
2.  **Create** `rsbuild.config.mjs` at the project root.
    *   Configure `source.entry` to point to your main entry file (likely `src/Main.bs.js` or `index.html` depending on Rsbuild's preference, usually it wants an HTML template that points to the JS).
    *   Set up the `server.proxy` to forward `/api` requests to `http://localhost:8080` (your Rust backend).
3.  **Create** a new `npm script` called `"rsbuild:dev"` to test it safely alongside the old `"dev"` script.

## Verification
*   Running `npm run rsbuild:dev` should start the Rsbuild server (even if it doesn't fully load the app yet, it should boot).
