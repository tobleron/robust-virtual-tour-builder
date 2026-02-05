# Improve App Reliability and Optimization

## Objective
Analyze code for logical inconsistencies impacting reliability and implement optimizations.

## Changes Implemented

### 1. Upload Batching & Throttling
- **File**: `src/systems/UploadProcessorLogic.res`
- **Issue**: Previously, `AddScenes` and `PersistenceLayer.performSave` were dispatched for *every single image* processed. This caused massive reducer overhead and IndexedDB write pressure during bulk uploads.
- **Fix**: Implemented a buffering mechanism in `executeProcessingChain`.
    - Items are buffered and flushed in chunks (default: 5 items).
    - `OperationJournal.updateContext` is throttled to update at most once per second.
    - Buffer is automatically flushed when processing completes.

### 2. Persistence Reliability
- **File**: `src/utils/PersistenceLayer.res`
- **Issue**: Auto-save errors were logged but swallowed, leaving users unaware of potential data loss.
- **Fix**: Added `EventBus.dispatch(ShowNotification(...))` in the error handler to alert users if auto-save fails.

### 3. InteractionQueue Stability
- **File**: `src/core/InteractionQueue.res`
- **Issue**: The stability check had a hard timeout (8s) that silently forced resolution, potentially masking real deadlocks or instability.
- **Fix**: Escalated the timeout log to `Logger.error` and added a user-facing warning via `EventBus`.

### 4. Security
- **File**: `src/systems/Api/AuthenticatedClient.res`
- **Issue**: Hardcoded `dev-token` fallback could theoretically be used in production.
- **Fix**: Added a `window.location.hostname` check to ensure the dev token is only used on `localhost` or `127.0.0.1`.

### 5. Test Fixes
- **Files**: `tests/unit/UploadProcessorLogic_v.test.res`, `tests/unit/App_v.test.res`, `tests/unit/Version_v.test.res`
- **Fixes**:
    - Mocked `OperationJournal`, `PersistenceLayer`, and `PanoramaClusterer` in upload tests to avoid timeouts.
    - Added missing `Sonner` mock to `App` tests.
    - Fixed `Version` assertion to allow `buildNumber` to be 0.

## Verification
- Ran `npm run test:frontend`. All 151 test suites passed.
