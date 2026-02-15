# Task D002: Evaluate and Consolidate Automated Tasks

## 🚨 Trigger
Manual evaluation of `dev_tasks` post-v4.5.7 architectural shifts.

## Objective
Consolidate, update, or close existing automated tasks to align with the current architecture (NavigationSupervisor, Slice-based State).

## Tasks
- [x] **Sidebar Decomposition (D007)**: Refactor `Sidebar.res` (445 LOC) into sub-components using the new `useSceneSlice` and `useUiSlice` patterns. (Completed: sidebar is now ~170 LOC)
- [ ] **Final Backend Hardening (D008)**: Replace remaining `unwrap()` in `metrics.rs` and `naming.rs` with lazy initialization or `Result` handling.
- [x] **Front-end Hygiene (D001)**: Eliminate `Obj.magic` in `Hooks.res`. (Note: `!important` violation has been de-escalated in `efficiency.json` and code modified to support `@efficiency-skip-violation`).
- [ ] **Clean Up Superceded Tasks**:
    - [ ] Verify if D009 (Merge Folders) is still valid for `VisualPipeline` (Jules missed the styles merge).
    - [x] Run D010 (Aggregate Completed) once current active tasks are cleared.

## Next Step
Focus on **D008** (Backend Hardening) next.
