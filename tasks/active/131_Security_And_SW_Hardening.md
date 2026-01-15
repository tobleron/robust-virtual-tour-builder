# Task: Security & Service Worker Hardening

## Status
- **Priority:** LOW
- **Estimate:** 2 hours
- **Category:** Security / Reliability

## Description
A security audit of the Content Security Policy (CSP) and a reliability check on the Service Worker assets.

## Requirements
1.  **CSP Audit:** Investigate if `unsafe-eval` and `unsafe-inline` can be removed or replaced with nonces. Check if Pannellum can function without `eval()`.
2.  **Service Worker Sync:** The `MANUAL_ASSETS` array in `service-worker.js` is currently hardcoded. Create a strategy (or build script) to ensure this list is automatically updated when files in the `public/` directory change.
3.  **Cache Versioning:** Ensure the `CACHE_NAME` in `service-worker.js` is automatically incremented based on the version in `package.json`.

## Expected Outcome
- More robust CSP.
- Zero "404 Not Found" errors during offline caching due to stale manual asset lists.
