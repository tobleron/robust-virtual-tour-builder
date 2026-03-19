# T1890 Troubleshoot Viewer Control CSS State And Waypoint Button

## Objective
Stabilize the builder viewer-control styling so disabled, busy, and active states are owned by a clear CSS architecture instead of scattered inline class strings and cross-file overrides, then fix the actual failing control path where the waypoint retarget `#` button in `src/components/PreviewArrow.res` remains orange during waypoint movement instead of graying out like the rest of the viewer controls. Preserve the current look and feel, keep export control styling visually aligned where equivalent controls exist, and avoid broad app-wide CSS churn outside the viewer slice.

## Hypothesis (Ordered Expected Solutions)
- [ ] The current failure is caused by targeting the wrong control path: the waypoint `#` button is defined in `src/components/PreviewArrow.res`, not in the utility bar or viewer label menu, so the existing CSS overrides never hit the actual DOM node.
- [ ] The viewer-control CSS is split across too many ownership layers (`buttons.css`, `floor-nav.css`, `viewer-ui-controls.css`, `viewer-ui-overlays.css`, and inline Tailwind classes), causing state styling to fight itself.
- [ ] Moving visual states into semantic CSS hooks and leaving only structural/layout classes in ReScript components will make disabled/busy styling deterministic.
- [ ] Export CSS should keep its generated delivery model, but its equivalent control states can be aligned through shared token values and clearer section ownership in `TourStyles.res`.

## Activity Log
- [ ] Create the task and move it to `tasks/active/`.
- [ ] Take the requested full snapshot checkpoint before refactoring.
- [ ] Audit current viewer control ownership and identify which rules belong in builder control CSS versus overlay positioning.
- [ ] Refactor builder viewer controls to semantic class/state hooks.
- [ ] Refactor viewer CSS ownership to remove viewer-specific logic from generic button files and reduce cross-file override conflicts.
- [ ] Fix the waypoint retarget `#` button disabled/busy styling in the actual `PreviewArrow` path.
- [ ] Align export viewer control tokens where equivalent controls exist.
- [ ] Run build verification and perform targeted manual state checks.

## Code Change Ledger
- [ ] Pending.

## Rollback Check
- [ ] Pending.

## Context Handoff
- [ ] The failing `#` control is the retarget button in `src/components/PreviewArrow.res`, not the utility-bar or label-menu `#` button. The viewer-control styling is currently split between CSS files and inline Tailwind state classes, which is why the previous overrides were unreliable. This task should centralize viewer-control state styling in CSS, preserve existing aesthetics, and keep export-side equivalents visually aligned without broad non-viewer CSS cleanup.
