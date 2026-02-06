# Task 1257: Fix Logical Inconsistencies (Upload/Resizer/Journal)

## Summary
While reviewing MAP.md/DATA_FLOW.md flows against current implementation, I found a few logic inconsistencies that can lead to silent misbehavior. This task proposes targeted fixes in upload preloading, memory telemetry, and operation journal cleanup.

## Problems Observed
1) Upload preloading no-op on first run
- Location: src/systems/UploadProcessorLogic.res
- In finalizeUploads, when `activeIndex == -1`, it dispatches `SetPreloadingScene(-1)`.
- `-1` is already the default and the comment indicates this path is intended to set a preloading scene for first run. This currently performs no preloading and can delay/skip anticipatory load.

2) Memory telemetry always falls back to N/A
- Location: src/systems/Resizer/ResizerUtils.res
- `safeGetMemoryStats` references `usedJSHeapSize`, `totalJSHeapSize`, and `jsHeapSizeLimit` without binding. This throws and forces the `None` path, so `getMemoryUsage()` always returns `N/A`.
- This undermines the memory telemetry included in `ResizerLogic.processAndAnalyzeImage` logging.

3) OperationJournal failed entries never clear
- Location: src/utils/OperationJournal.res
- `completeOperation` filters to keep `Pending`, `InProgress`, `Failed`, `Interrupted` entries, dropping only Completed/Cancelled.
- `getInterrupted` ignores `Failed`, and there is no UI for failed entries. So failed entries accumulate permanently without visibility or cleanup, which is inconsistent with the journal being used for recovery/pending operations only.

## Proposed Fixes
1) Upload preloading
- When `activeIndex == -1` and uploads complete, set `preloadingSceneIndex` to the first available scene index (likely `0`, or index of the first newly added scene if there are existing scenes).
- Ensure it triggers `ViewerManagerLogic.usePreloading` exactly once.

2) Memory telemetry
- Replace `safeGetMemoryStats` with a proper access of `Window.performance.memory` (guarded for availability). Example:
  - `switch Js.Nullable.toOption(Window.performance)` then `performance["memory"]` and map to the three values.
- Keep try/catch but avoid referencing unbound identifiers.

3) OperationJournal cleanup
- Decide on desired behavior:
  - If journal is for recovery/pending only: remove `Failed` entries in `completeOperation` cleanup path (and consider adding a `prune` function for `failOperation`).
  - If journal is for history: keep Completed too and add UI/retention policy.
- Recommended minimal fix: treat `Failed` as terminal and drop it from `pendingOnly` filtering so the journal doesn't grow unbounded.

## Acceptance Criteria
- First upload after an empty project sets `preloadingSceneIndex` to a valid scene index and triggers anticipatory load.
- Resizer memory telemetry logs actual values on supported browsers instead of `N/A`.
- Failed operations do not persist indefinitely in `OperationJournal` unless there is explicit UI/retention support.

## Files
- src/systems/UploadProcessorLogic.res
- src/components/ViewerManagerLogic.res (validate preloading behavior; no change expected)
- src/systems/Resizer/ResizerUtils.res
- src/utils/OperationJournal.res
