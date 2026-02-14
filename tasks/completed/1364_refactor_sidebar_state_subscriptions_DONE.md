q# Task: Refactor Sidebar State Subscriptions for Performance

## Objective
Decouple `Sidebar.res` from the global application state to prevent unnecessary re-renders during camera movement (exploration).

## Context
The architectural audit (v4.5.3) identified that `Sidebar.res` currently uses `AppContext.useAppState()`. The global state includes `activeYaw` and `activePitch`, which update at 60fps during user rotation. This causes the entire Sidebar (and its complex sub-components) to re-render constantly, leading to high CPU usage and potential input lag.

## Requirements
- [ ] Audit `src/components/Sidebar.res` and its sub-modules (`SidebarLogic`, `SidebarActions`, etc.).
- [ ] Replace `useAppState()` with specialized slice hooks:
    - `useSceneSlice()` for tour name and scene list updates.
    - `useUiSlice()` for mode and linking state.
    - `useAppDispatch()` for actions.
- [ ] Ensure that no component in the Sidebar hierarchy is subscribed to the top-level `state` object.
- [ ] Verify using React DevTools (Profiler) that camera rotation no longer triggers Sidebar re-renders.

## Acceptance Criteria
- [ ] Sidebar components do not re-render when `activeYaw` or `activePitch` changes.
- [ ] All Sidebar functionality (Upload, Save, Export, Tour Name Editing) remains fully functional.
- [ ] No regressions in state synchronization between the local tour name input and global state.
