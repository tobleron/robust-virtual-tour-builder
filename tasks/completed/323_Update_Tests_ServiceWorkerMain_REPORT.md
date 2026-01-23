# Task 323: Update Unit Tests for ServiceWorkerMain.res - REPORT

## Objective
Update `tests/unit/ServiceWorkerMainTest.res` to ensure it covers recent changes in `ServiceWorkerMain.res`.

## Fulfilment
- Reviewed `src/ServiceWorkerMain.res` and identified that it primarily contains service worker lifecycle logic and asset lists.
- Migrated the test to Vitest by creating `tests/unit/ServiceWorkerMain_v.test.res`.
- Added tests for:
    - `cacheName` constant verification.
    - `manualAssets` content verification (ensuring core files like `/index.html` and `/manifest.json` are present).
    - Existence and accessibility of core service worker bindings.
- Removed legacy `tests/unit/ServiceWorkerMainTest.res` and updated `tests/TestRunner.res`.
- Verified compilation and test execution via `npx vitest run tests/unit/ServiceWorkerMain_v.test.bs.js`.
