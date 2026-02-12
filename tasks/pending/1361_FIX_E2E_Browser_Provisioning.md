# [1361] FIX: E2E Browser Provisioning

## Objective
Ensure all required browser binaries (Chromium, Firefox, Webkit) are correctly provisioned in the execution environment before running the full E2E test suite.

## Context
Full E2E test runs failed because `firefox` and `webkit` executables were missing in the environment. While `chromium` was manually installed, the system should ideally automate or more clearly document the provisioning requirements for the full suite.

## Deliverables
1. Updated `scripts/setup.sh` or a new `scripts/install-browsers.sh` to handle browser provisioning.
2. Refined `playwright.config.ts` to better handle missing browsers (e.g., skip instead of fail if a browser is unavailable in a specific dev context).

## Verification
- `npm run test:e2e` successfully attempts to run across all configured projects.
