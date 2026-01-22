# Task: Add Tests for UploadProcessor.res

## Context
A bug was fixed in `UploadProcessor.res` where duplicate uploads (resulting in an empty processing queue) caused the progress bar to hang. The fix was applied without a regression test due to the complexity of mocking dependencies (`Resizer`, `BackendApi`, `GlobalStateBridge`) for the internal `processWithQueue` closure.

## Objective
Create unit tests for `src/systems/UploadProcessor.res`.

## Specific Requirements
1.  **Test Duplicate Handling**: Verify that if all items are duplicates, the processor completes successfully and reports the duplicates.
2.  **Test Empty Queue**: Verify that `processWithQueue` handles empty arrays correctly.
3.  **Mock Dependencies**: You will likely need to mock `Resizer.processAndAnalyzeImage` and `BackendApi` calls.

## Reference
- Fix applied in session on 2026-01-23.
- Logic is in `processWithQueue` function.
