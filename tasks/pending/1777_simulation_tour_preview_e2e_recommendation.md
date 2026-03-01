# 1777_simulation_tour_preview_e2e_recommendation.md
## Goal
- Add regression-proof measures and regression tasks covering both the simulation-tour preview failing spec and the port contention introduced by repeated `npm run test:e2e` runs.

## Background
- During the latest run the suite failed at `tests/e2e/accessibility-comprehensive.spec.ts:102` while executing the simulation-tour preview flows, and a new pop-up failure was encountered by the user when trying to rerun the suite due to port 3000 already being bound from a previous run.
- We suspect the `page.locator(...live region selector).count()` polling is hitting a closed page, and the port contention occurs because Playwright’s built-in server does not automatically stop when the suite aborts.

## Tasks
1. Investigate the accessibility spec to confirm why the page closes preemptively (e.g., an upstream navigation interruption, aborted preview flow, or missing waiting/abort handling). Record the direct cause with code references so the fix can target it precisely.
2. Implement a durable guard for the simulation preview test flow so that the hotspot/auto-advance path does not close the page before the live-region locator is validated. This may include injecting a delay, ensuring asynchronous operations complete, or revising the test markup to keep the page alive.
3. Harden the Playwright web server setup so `npm run test:e2e` either reuses an existing server or guarantees complete teardown. Document the chosen approach and the verification steps used to confirm the port no longer remains bound after each run.
4. Update the task with the verification results and the new artifacts (if any) so future reruns can reference the stabilized workflow.

## Verification
- `npm run test:e2e` passes the live-region accessibility spec with the scene navigation running to completion and does not leave port 3000 engaged after the run.
- The simulation-tour preview flow’s test artifacts (traces/screenshots) show the flow now completes successfully and the port-warning error no longer appears.
