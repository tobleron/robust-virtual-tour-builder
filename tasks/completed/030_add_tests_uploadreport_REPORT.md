# Task 030: Add Unit Tests for UploadReport - REPORT

## Objective
The objective was to create a unit test file `tests/unit/UploadReport_v.test.res` to verify the logic in `src/components/UploadReport.res`.

## Fulfillment
The task was completed by:
1.  **Test Creation**: A new test file `tests/unit/UploadReport_v.test.res` was created using Vitest.
2.  **Implementation**: The tests verify the `UploadReport.show` logic by subscribing to `EventBus` and asserting that the `ShowModal` event is dispatched (or not) based on the input report data.
3.  **Compilation**: The ReScript files were compiled manually using `npm run res:build` (after terminating a stuck watcher process).
4.  **Verification**: The tests were verified using `npm run test:frontend`, passing successfully.