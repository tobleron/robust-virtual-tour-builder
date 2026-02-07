# Task 1243: Fix Operation Cancellation Feedback Visibility

## Objective
Ensure that cancelling a long-running operation provides clear visual feedback by preventing premature hiding of the progress bar.

## Problem Analysis
- When an operation is cancelled, `SidebarLogic.res` calls `updateProgress` with `active: false`.
- `ProgressBar.res` interprets `visible: false` (from `!active`) by immediately setting opacity to 0 and hiding the element.
- This prevents the user from seeing the "Cancelled" status message.

## Proposed Solution
- Modify `ProgressBar.res` to handle the "Cancelled" text specially: show the message, wait for `Constants.progressBarAutoHideDelay`, and then hide, even if `visible` is false.
- Alternatively, keep `visible: true` during the "victory lap" of the cancellation message.

## Acceptance Criteria
- [ ] "Cancelled" feedback is visible upon operation cancellation.
- [ ] Corresponding test in `robustness.spec.ts` passes.
