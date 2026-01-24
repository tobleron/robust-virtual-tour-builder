# Task 325: Update Unit Tests for Logger.res - REPORT

## Objective
Update `tests/unit/Logger_v.test.res` to ensure it covers recent changes in `Logger.res`.

## Fulfilment
- Reviewed `src/utils/Logger.res` and identified new utilities: `perf`, `timed`, `timedAsync`, and `attempt`.
- Updated `tests/unit/Logger_v.test.res` to include tests for these new features:
    - Verified `perf` maps duration to correct log levels (Warn/Info/Debug).
    - Verified `timed` and `timedAsync` (using `testAsync`) correctly measure operation duration and return results.
    - Verified `attempt` correctly catches and logs exceptions while returning a `Result`.
- Verified all tests pass by running `npx vitest run tests/unit/Logger_v.test.bs.js`.
