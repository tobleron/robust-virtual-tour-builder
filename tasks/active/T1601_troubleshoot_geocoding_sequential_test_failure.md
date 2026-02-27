# T1601 Troubleshoot Geocoding Sequential Test Failure

- Assignee: Codex
- Objective: Restore deterministic passing behavior for `api::geocoding::tests::test_api_suite_sequential` without regressing geocoding endpoint behavior.
- Scope: `backend/src/api/geocoding.rs` and tightly related geocoding test helpers only.

## Hypothesis (Ordered Expected Solutions)
- [x] H1: Shared global geocoding cache state leaks across tests, causing assertion drift in sequential suite.
- [x] H2: Test ordering assumes a pristine cache but setup does not reset state in all branches.
- [x] H3: Time/order-sensitive assertion is too strict and should validate behavior contract instead of exact counter.

## Activity Log
- [x] Reproduce failing test in isolation and full backend run.
- [x] Inspect failing assertion and surrounding setup/teardown.
- [x] Patch minimal deterministic reset/setup logic.
- [x] Re-run targeted geocoding tests.
- [x] Re-run backend tests to ensure no regression.

## Code Change Ledger
- [x] `backend/src/services/geocoding/cache.rs`: Added shared `GEOCODING_TEST_MUTEX` under `#[cfg(test)]` for cross-module geocoding test serialization. Revert note: remove test mutex block.
- [x] `backend/src/services/geocoding/mod.rs`: Locked `test_geocoder_suite_sequential` with shared geocoding test mutex. Revert note: remove guard line.
- [x] `backend/src/api/geocoding.rs`: Locked `test_api_suite_sequential` and `test_geocode_success` with shared geocoding test mutex to prevent parallel cache mutation races. Revert note: remove guard lines.

## Rollback Check
- [x] Confirmed CLEAN (all troubleshooting changes are active, intentional, and validated).

## Context Handoff
- [x] Geocoding sequential suite intermittently failed due to shared singleton cache mutation from parallel tests in same module family.
- [x] Added a shared test-only mutex in geocoding cache layer and used it in both API/service geocoding tests.
- [x] Full backend test suite now passes with no geocoding sequential failure.
