# Task 296: Add Unit Tests for PopOver.res - REPORT

## Objective
The objective was to create unit tests for `src/components/PopOver.res`, a custom popover component with complex positioning and portal logic.

## Implementation Details
1.  **Test Creation**: Created `tests/unit/PopOver_v.test.res` to verify positioning, clamping, and event handling.
2.  **Mocking Environment**:
    -   Implemented a robust global mock for `getBoundingClientRect` to simulate different anchor and popover dimensions.
    -   Mocked `window.innerWidth` and `window.innerHeight`.
3.  **Functionality Tested**:
    -   **Basic Positioning**: Verified that the popover renders in a portal and calculates the correct top/left based on the anchor.
    -   **Outside Click**: Verified that clicking outside the popover (on `document.body`) triggers the `onClose` callback.
    -   **Auto-Repositioning**: Verified that the component correctly switches to `TopLeft` alignment when there is insufficient space below the anchor.
    -   **Viewport Clamping**: Verified that the popover position is clamped to keep it within the viewport boundaries (respecting the 8px offset).
4.  **ReBindings Updates**: Added missing `getAttribute` to `Dom` module and `dispatchEvent` to `Window` module in `src/ReBindings.res` to support the tests.

## Results
- **Coverage**: All core logic branches in `PopOver.res` (position calculation, clamping, auto-alignment, event listeners) are covered.
- **Verification**: Tests pass successfully.
- **Build**: Project build and all unit tests pass without regressions.
