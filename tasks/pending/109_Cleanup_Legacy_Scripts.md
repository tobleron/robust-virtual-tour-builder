# Task: Cleanup Legacy Build Scripts
**Priority:** Low (Cleanup)
**Status:** Pending

## Objective
Remove the old manual build scripts once Rsbuild is fully verified.

## Context
We no longer need `live-server`, `start_dev.sh`, or the manual `css:watch` scripts.

## Requirements
1.  **Delete** `start_dev.sh`.
2.  **Uninstall** `live-server` (if it was a dependency).
3.  **Clean up** `package.json`: Remove `css:build`, `css:watch` (since Rsbuild handles it), and any other unused scripts.
4.  **Document**: Update `README.md` to explain how to start the app with the new system (`npm run dev`).

## Verification
*   Project is cleaner.
*   `npm run dev` works perfectly.
