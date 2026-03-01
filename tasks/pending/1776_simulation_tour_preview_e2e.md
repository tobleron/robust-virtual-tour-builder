# 1776_simulation_tour_preview_e2e.md
## Goal
- Restore the simulation-mode tour-preview E2E test so it consistently runs to completion on `npm run test:e2e` without early port conflicts or hangs.
- Capture the remaining failure context from `tests/e2e/accessibility-comprehensive.spec.ts` as part of the verification step, ensuring the simulation scenario referenced by the user request works end-to-end.

## Background
- The suite currently aborts at `chromium › ... › should have ARIA live regions for announcements` because the target page or locator is closing before the assertion resolves; Playwright reports the page was closed and leaves artifacts under `test-results/accessibility-comprehensiv-*/`.
- When rerunning the suite, the WebServer instance frequently stays bound to port 3000, so the test fails instantly unless the old server is killed.

## Tasks
1. Ensure the Playwright web server is cleanly shut down between runs or configure Playwright to reuse an existing server so that repeated `npm run test:e2e` executions do not fail with `http://localhost:3000 is already used`.
2. Investigate why the simulation-tour preview scenario (the user-requested test) is not considered “failed” early—verify the test suite still proceeds through the simulation preview flow when rerun after stabilization.
3. Re-run `npm run test:e2e` after the clean-up to confirm the simulation preview path passes (fingerprinting the `tests/e2e/simulation-preview` spec if present).
4. Update this task with the failing artifacts (traces/screenshots) and the steps taken to fix the port contention so future runs can reproduce the stabilization steps.

## Verification
- `npm run test:e2e` must complete past the simulation-tour preview tests without leaving port-3000 conflicts.
- The previously failing accessibility spec should now reach the live-region assertion (or be skipped/reworked if the failure cannot be avoided yet) while the simulation preview path finishes successfully.
