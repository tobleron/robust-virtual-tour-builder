# T1858 Troubleshoot Global Connectivity Degraded Grayscale Scope

## Objective

Ensure the connectivity degraded/offline state greyscales the entire application shell, not just the viewer canvas, while keeping the connectivity retry toast fully colored and readable.

## Hypothesis (Ordered Expected Solutions)

- [ ] The grayscale filter is currently attached only to viewer/project-load selectors in CSS, so the sidebar/app shell never enters the degraded visual treatment.
- [ ] The degraded overlay is mounted globally, but the notification container is inside the same filtered layer, so toast exclusion must be done with selector isolation rather than moving the overlay alone.
- [ ] The shell/root layout lacks a stable class hook for app-wide degraded styling, so the fix may require targeting the main app chrome container directly.

## Activity Log

- [x] Read MAP.md, DATA_FLOW.md, tasks/TASKS.md, and ReScript standards.
- [x] Inspect degraded connectivity UI flow and CSS scope.
- [x] Patch app-wide grayscale behavior while preserving colored retry toast.
- [x] Revert the top-level toast-host relocation after it pulled the notification outside the viewer stage.
- [x] Re-scope degraded filtering to the sidebar and viewer-stage children while restoring the toast mount inside the stage.
- [x] Verify build.

## Code Change Ledger

- [x] `src/App.res` - kept the stable `#app-shell` wrapper, but remounted `NotificationCenter` inside `#viewer-stage` so the retry toast stays visually inside the stage window.
- [x] `src/components/ViewerHUD.res` - kept the duplicate toast host removed from `ViewerHUD` so the stage owns the single notification mount.
- [x] `css/layout.css` - replaced the rejected whole-shell filter with precise degraded selectors for `#sidebar`, `#viewer-stage` children, `#placeholder-text`, and `#modal-container`; reduced the overlay back to dim-only.
- [x] `css/components/ui.css` - restored the notification container to `position: absolute` so it anchors to the stage again instead of the browser viewport.

## Rollback Check

- [x] Confirmed CLEAN. No non-working exploratory changes were left in source.

## Context Handoff

The connectivity degraded state still toggles `body.network-degraded` from `OfflineBanner.res`, but the correct fix was not a top-level toast mount. The stable approach is to keep the toast inside `#viewer-stage`, restore its stage-relative positioning, and grayscale the rest of the app by targeting the sidebar and stage children explicitly while leaving the notification container untouched. Build verification is required after any follow-up CSS tuning because the user wants this to remain the default degraded UX.
