# T1786 - Fix Title Discovery Race Condition

## Assignee: Gemini
## Capacity Class: A
## Objective
Prevent race conditions where multiple concurrent upload batches might incorrectly clear the `isDiscoveringTitle` global flag, leaving the UI unlocked while a background process is still running.

## Context
Currently, `isDiscoveringTitle` is a simple boolean. If Batch A starts (flag=true) and then Batch B starts (flag=true), and then Batch A finishes (flag=false), the UI unlocks even though Batch B is still running.

## Strategy
1.  **Refactor State**: Change `isDiscoveringTitle` from `bool` to `int` (reference counter) in `Types.res` and `State.res`.
2.  **Update Logic**:
    *   Start Discovery -> Increment counter.
    *   Finish Discovery -> Decrement counter.
    *   UI Lock -> Locked if `counter > 0`.
3.  **Verify**: Ensure the UI remains locked until *all* concurrent discovery tasks are complete.

## Boundary
- `src/core/Types.res`
- `src/core/State.res`
- `src/core/NavigationProjectReducer.res`
- `src/systems/Upload/UploadReporting.res`
- `src/components/Sidebar/SidebarProjectInfo.res` (UI logic update)
