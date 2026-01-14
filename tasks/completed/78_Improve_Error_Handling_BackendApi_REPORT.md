# Task 78: Improve Error Handling in BackendApi.res - REPORT

## Summary
Improved error handling across all backend API calls by establishing a consistent `apiResult` pattern. Replaced silent error swallowing with proper error propagation using ReScript's `result` type, while ensuring all failures are logged for debugging.

## Changes
- **Established Patterns**:
    - Defined `apiResult<'a> = result<'a, string>` at the top of `BackendApi.res` as a standard for all API operations.
- **Refactored API Functions**:
    - `batchCalculateSimilarity`: Now returns `apiResult`, allowing `UploadProcessor` to detect and report clustering failures.
    - `calculatePath`: Now returns `apiResult`, improving reliability for teaser generation.
    - `processImageFull`: Now returns `apiResult`, notifying the caller if optimization fails.
    - `importProject`: Now returns `apiResult`, ensuring the UI can show meaningful errors during project loading.
    - `reverseGeocode`: Enhanced with active logging for both service unavailability and fetch failures, while maintaining user-friendly fallback strings.
    - Refactored `validateProject`, `loadProject`, `extractMetadata`, and `saveProject` to follow the same pattern.
- **Updated Callers**:
    - `UploadProcessor.res`: Updated to handle clustering errors and notify the user if grouping fails.
    - `TeaserManager.res`: Updated to handle path generation errors and abort teaser recording with a notification.
    - `ProjectManager.res`: Updated `loadProjectZip` to gracefully handle import failures.
    - `Resizer.res`: Updated `processAndAnalyzeImage` to correctly propagate errors from the backend optimization service.

## Verification Results
- **Build**: Successfully compiled with `npm run res:build`.
- **Error Propagation**: Verified that errors are both logged via `Logger` and propagated through the promise chain as `Error(msg)`.
- **UI Notifications**: Callers now use `EventBus.dispatch(ShowNotification(...))` to alert the user of backend failures.
