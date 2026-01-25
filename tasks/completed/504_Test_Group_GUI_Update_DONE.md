# Task 504: Update Unit Tests for GUI Components (DONE)

## 🚨 Trigger
Multiple GUI component implementation files are newer than their tests.

## Objective
Update the corresponding unit tests for the following components to ensuring they cover recent changes and maintain 100% code coverage.

## Sub-Tasks
- [x] **Portal** (`src/components/Portal.res`) - Verified existing tests cover new usage.
- [x] **PopOver** (`src/components/PopOver.res`) - Added test for `isTooltip` prop.
- [x] **ProgressBar** (`src/components/ProgressBar.res`) - Added tests for `upload-label`, `spinner` opacity, and sidebar scrolling. Updated mocks.
- [x] **Tooltip** (`src/components/Tooltip.res`) - Verified.
- [x] **PreviewArrow** (`src/components/PreviewArrow.res`) - **NEW TEST** Created comprehensive test suite covering rendering, right-click toggle, and delete actions.
- [x] **LabelMenu** (`src/components/LabelMenu.res`) - Verified.
- [x] **HotspotActionMenu** (`src/components/HotspotActionMenu.res`) - Verified.
- [x] **ErrorFallbackUI** (`src/components/ErrorFallbackUI.res`) - Verified.

## Implementation Details
- Created `tests/unit/PreviewArrow_v.test.res` with mocks for `dispatch`, `state`, and `EventBus` verification.
- Updated `tests/unit/ProgressBar_v.test.res` to mock `sidebar-content` query and test new UI logic.
- Updated `tests/unit/PopOver_v.test.res` to check `isTooltip` class.
- Verified all tests pass with `npm run test:frontend`.
- Verified build passes with `npm run build`.

## Verification
- `npm run test:frontend` passed.
- `npm run build` passed.
