# T1619 - Troubleshoot teaser start scene + cancel/ESC regression

## Objective
Find why teaser no longer auto-switches to first scene at start and why cancel/ESC does not stop generation reliably, then apply a minimal safe fix without regressing recent reliability work.

## Hypothesis (Ordered Expected Solutions)
- [ ] Highest probability: teaser runtime no longer triggers deterministic "go home/first scene" prep before recording start.
- [ ] Cancel/ESC toggles UI state (`isTeasing`) but does not abort the active renderer/recording pipeline signal.
- [ ] `WAIT_FOR_VIEWER_TIMEOUT` loop ignores abort state and continues to next shot despite cancellation.
- [ ] Dynamic import path introduced a stale closure around signal/onCancel wiring.

## Activity Log
- [x] Create troubleshooting task.
- [x] Reproduce with standard fixture and capture logs.
- [x] Trace teaser start sequence and first-scene alignment logic.
- [x] Trace ESC/cancel through OperationLifecycle + teaser renderer abort checks.
- [x] Implement surgical fix.
- [x] Verify build.
- [ ] Verify manually in-browser teaser run (dev server runtime check pending).

## Code Change Ledger
- [x] `src/systems/TeaserOfflineCfrRenderer.res`:
  - Added deterministic first-shot bootstrap before render loop: force `SetActiveScene` to first manifest shot and wait until viewer scene metadata matches.
  - Added `waitForViewerReadyOrAbort` helper to poll viewer readiness with abort checks.
  - Changed per-scene transition wait to abort-aware wait and fail fast on timeout (`ViewerReadyTimeout`) instead of silently continuing.
  - Revert note: remove bootstrap/wait helper and restore plain `Playback.waitForViewerReady` calls if this path is superseded by centralized navigation orchestration.
- [x] `src/systems/TeaserPlayback.res`:
  - Kept public `waitForViewerReady(sceneId)` signature unchanged for compatibility with `TeaserPlaybackManifest` call sites.
  - Revert note: none (no behavioral regression introduced beyond preserving interface).

## Rollback Check
- [ ] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
User reports teaser regression: no forced switch to first scene before recording and cancel/ESC does not stop generation. Console shows repeated `TeaserLogic WAIT_FOR_VIEWER_TIMEOUT` and eventual recording stop/save after ESC. Investigation will focus on teaser start orchestration and abort propagation in headless/offline teaser rendering.
