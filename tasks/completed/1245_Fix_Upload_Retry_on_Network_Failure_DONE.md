# Task 1245: Fix Upload Retry on Network Failure

## Objective
Ensure that network failures during image uploads correctly trigger the automatic retry mechanism with exponential backoff.

## Problem Analysis
- `Retry.res` is designed for general async operations, but its integration in `AuthenticatedClient.res` might not be correctly catching all types of network failures (e.g., `net::ERR_INTERNET_DISCONNECTED` vs a 500 error).
- Playwright tests show `net::ERR_ABORTED` which might be treated as a terminal failure rather than a retryable one.

## Proposed Solution
- Update `AuthenticatedClient.res` to treat network-level exceptions (caught in `try...catch`) as retryable errors.
- Ensure `UploadProcessor.res` correctly uses `requestWithRetry` for all critical image-processing calls.

## Acceptance Criteria
- [ ] Uploads automatically retry after a network error.
- [ ] User is notified of the retry attempt.
- [ ] Corresponding test in `error-recovery.spec.ts` passes.
