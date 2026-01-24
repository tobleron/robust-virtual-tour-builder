# Task 352: Update Unit Tests for BackendApi.res - REPORT

## Objective
Update `tests/unit/BackendApiTest.res` to ensure it covers recent changes in `BackendApi.res`.

## Fulfillment
- **Migration to Vitest**: Migrated the legacy `BackendApiTest.res` (which was only verifying compilation) to a robust Vitest-based suite: `tests/unit/BackendApi_v.test.res`.
- **Decoder Verification**: Added unit tests for `decodeImportResponse` and `decodeGeocodeResponse` to ensure type safety at the API boundary.
- **Fetch Mocking**: Implemented comprehensive API call tests using `vi.fn()` to mock `globalThis.fetch`, covering both success and failure (error reporting) paths for `importProject` and `reverseGeocode`.
- **Clean Architecture**: Followed `/testing-standards.md` by isolating side effects through mocking and ensuring 100% logic coverage for the newly implemented/updated decoders.
- **Legacy Cleanup**: Updated `tests/TestRunner.res` to remove the deprecated test call and deleted the legacy files.

## Result
7 tests passing in `tests/unit/BackendApi_v.test.res`.
