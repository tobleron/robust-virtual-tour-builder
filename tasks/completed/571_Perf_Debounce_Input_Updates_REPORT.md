# Task 571 Report: UI Performance - Debounce Project Name

## Objective
The goal was to eliminate "input lag" caused by high-frequency global state updates when typing in the "Project Name" field in the Sidebar. Previously, every keystroke triggered a full Redux-style dispatch and re-render of the app.

## Implementation Details
1.  **Local State**: Introduced `localTourName` state in `Sidebar.res` to handle immediate UI feedback during typing.
2.  **Debouncing**: Implemented a 300ms debounce mechanism using `useEffect` and `setTimeout`. The global action `SetTourName` is now only dispatched after the user pauses typing.
3.  **Synchronization**: Added logic to sync `localTourName` with the global store (`sceneSlice.tourName`) when external updates occur (e.g., loading a project), ensuring the input doesn't desync from the source of truth.

## Technical Changes
- Modified `src/components/Sidebar.res`:
    - Added `localTourName` and `setLocalTourName`.
    - Added `expectedTourName` ref for robust synchronization.
    - Replaced direct value binding with local state.

## Verification
- **Typing**: Typing should now feel instantaneous regardless of scene count.
- **Data Integrity**: The project name updates in the store (and header, if applicable) after a short delay.
- **Loading**: Loading a new project correctly updates the input field to the new name.
