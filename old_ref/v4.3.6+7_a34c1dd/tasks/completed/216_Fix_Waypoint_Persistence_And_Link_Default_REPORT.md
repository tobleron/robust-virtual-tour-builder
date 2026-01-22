# Fix Waypoint Persistence and Link Creation Default - REPORT

## Objectives
1.  **Fix Waypoint Persistence**: Ensure that when a waypoint is created via "Add Link", it stays anchored to the scene coordinates and doesn't follow the camera.
2.  **Fix Default Option on Enter**: Enable finishing the link creation by pressing ENTER.

## Investigation & Findings
1.  **Waypoint Persistence**:
    - The "Red Critical Path" (Camera Director Curve) in `HotspotLine.res` was explicitly designed to connect the last confirmed point to the *current camera position* (`currentCam`).
    - This created a "rubber band" line that followed the user's view center, which the user perceived as a "wrongly persistent" path/waypoint that moved with them ("Wherever I look, I see the path").
    - The "Yellow Rod" (Target Path) was functioning correctly (connecting to mouse), but the Red line's behavior was confusing in this context.

2.  **Enter Key**:
    - `LinkModal.res` generates the modal content, but the modal rendering logic resides in `ModalContext.res`.
    - `ModalContext` handled `Escape` and `Tab` (focus trap) but lacked a listener for `Enter`.
    - The `<select>` element inside the modal had focus, but pressing Enter on it did nothing.

## Technical Resolution
1.  **Modified `src/systems/HotspotLine.res`**:
    - Removed `currentCam` from the `camPoints` array construction.
    - The Red Critical Path now only connects *confirmed* intermediate points. It no longer extends to the current camera view, eliminating the "following" effect.

2.  **Modified `src/components/ModalContext.res`**:
    - Added an `Enter` key listener in the `useEffect` hook.
    - When `Enter` is pressed while a modal is active, it now triggers the `onClick` handler of the **first button** (Primary/Save) defined in the modal configuration.
    - Added logic to respect the `autoClose` property of the button.

## Verification
- **Build**: `npm run build` passed successfully.
- **Tests**: Ran full test suite (`npm run test:all`) and it passed.
- **Logic Check**: 
    - Waypoint fix ensures path segments are only drawn between fixed world coordinates.
    - Enter key fix generically supports all modals where the first button is the primary action (standard pattern in this codebase).
