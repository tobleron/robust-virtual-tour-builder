# T1901 Troubleshoot Dashboard Project Boot Progress Gate

## Hypothesis (Ordered Expected Solutions)
- [ ] The dashboard builder-open path preloads project JSON before the builder lifecycle starts, so the user misses the normal project-load progress phase and can briefly see a partial builder state.
- [ ] Saved-project loads are using the same project-load operation type, but the sidebar progress card is allowed to stay hidden for the first 500ms, making dashboard opens feel ungated compared with local file imports.
- [ ] The builder needs an explicit boot curtain for dashboard-triggered opens so the viewer remains inaccessible until the saved-project load promise completes and viewer readiness settles.

## Activity Log
- [x] Read `MAP.md`, `DATA_FLOW.md`, and `tasks/TASKS.md`.
- [x] Inspect the dashboard open path in `src/index.js`, `src/site/PageFramework.js`, and `src/site/PageFrameworkBuilder.js`.
- [x] Inspect the project-load lifecycle in `src/components/Sidebar/SidebarProjectLoadFlow.res` and readiness handling modules.
- [x] Unify the dashboard boot experience with the saved-project load lifecycle and add explicit blocking until ready.
- [x] Replace the blind post-ready delay with a real stabilization probe based on viewer readiness, main-thread long-task quiet time, and consecutive stable animation frames.
- [x] Verify the builder/dashboard load path with `npm run build`.

## Code Change Ledger
- [x] `src/site/PageFrameworkBuilder.js` - Added a builder boot overlay state/DOM bridge so dashboard-triggered builder opens can block the viewer immediately before the ReScript app finishes mounting.
- [x] `src/site/PageFramework.js` - Ensured the builder boot overlay is created alongside the existing builder shell overlays.
- [x] `src/index.js` - Marked dashboard-triggered builder opens as boot-pending before mount and kept the boot overlay active while saved project payloads are fetched.
- [x] `src/Main.res` - Started the builder from `State.initialState` when a boot-pending saved project is requested so stale session state does not render underneath the dashboard-open flow.
- [x] `src/AppEffects.res` - Cleared the builder boot overlay only after the saved-project load promise finishes, including the readiness wait path.
- [x] `src/components/Sidebar/SidebarProjectLoadFlow.res` - Made saved-project loads visible immediately in the sidebar processing UI by setting `visibleAfterMs=0`.
- [x] `css/components/site-pages-builder.css` / `src/site/PageFrameworkBuilder.js` - Simplified the dashboard boot curtain into a transparent viewer click-block and reused `project-load-mode` body styling instead of a separate custom loading card.
- [x] `src/components/Sidebar/SidebarProjectLoadReadiness.res` - Switched the readiness check to the stronger active-viewer-for-scene signal, increased the timeout budget, and replaced the blind final delay with a 3-second interactivity-stability probe that waits for quiet long-task windows and consecutive stable animation frames before unlocking.
- [x] `css/components/ui.css` - Changed the project-load progress bar theme from cyan+blue to orange+blue so sidebar and dashboard-triggered project loads share the same accepted visual treatment.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
- [x] Dashboard project opens still preload the saved project payload before the ReScript builder mounts, but they now reuse the same `project-load-mode` greyscale treatment instead of a separate custom card.
- [x] Once the builder mounts, the saved-project load shows the sidebar progress card immediately and keeps the viewer blocked until the stage passes a 3-second stability probe rather than just hitting the first ready signal.
- [x] The builder boot click-block is cleared only after the saved-project load promise settles, so the viewer is no longer accessible during partial dashboard-driven loads.
