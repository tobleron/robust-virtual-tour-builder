# 1820 Unit Test Alignment And E2E Stabilization

## Context
- The repo has gone through broad refactoring and helper extraction, so test coverage and selectors need to be brought back into sync with the current source tree.
- Goal: make the unit test suite represent the latest code shape, then fix Playwright failures so `npm run test:e2e` runs without unexpected failures.
- Scope covers frontend unit tests, Playwright E2E tests, and the minimum product code changes required to restore valid behavior and stable selectors.

## Objectives
- Audit the current frontend unit tests against the latest source structure and behavior.
- Remove, rewrite, or replace stale tests that still target deleted/refactored modules.
- Run the frontend unit suite and fix failures until it is current.
- Run the Playwright suite, classify failures, and fix real product or test issues until the suite is stable.
- Keep the task in `active/` until user sign-off after verification.

## Verification Target
- `npm run test:frontend`
- `npm run test:e2e`
- `npm run build`

## Notes
- Prefer fixing test intent drift before adding new coverage.
- If a Playwright failure is caused by a genuine product regression, fix the product code instead of weakening the test.
