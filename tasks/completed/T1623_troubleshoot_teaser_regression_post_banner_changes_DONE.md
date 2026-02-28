# T1623 - Troubleshoot teaser regression after export/banner edits

## Objective
Identify why teaser generation regressed after recent banner-related edits and isolate the minimal culprit without reverting unrelated reliability/performance work.

## Hypothesis (Ordered Expected Solutions)
- [ ] H1: Recent HUD overlay changes in teaser pipeline (`TeaserRecorderHud` / `TeaserRecorder` / `TeaserOfflineCfrRenderer`) introduced rendering-path side effects that break teaser completion.
- [ ] H2: Export template/banner changes indirectly impacted shared teaser timing/progress behavior through common modules/constants.
- [ ] H3: Regression is pre-existing in current branch state and only surfaced now; recent changes are not the direct root cause.

## Activity Log
- [x] Capture current HEAD and working-tree status for teaser/export files.
- [x] Diff teaser files against last committed baseline.
- [x] Diff teaser files against last known stable commit (`be11c8dd` baseline if unchanged in commit history).
- [x] Identify exact behavioral deltas (flow, cancellation, wait loops, overlay rendering).
- [x] Propose minimal, reversible fix plan with risk notes.
- [x] Apply surgical rollback of teaser-only banner integration modules.
- [x] Run focused teaser unit verification after rollback.
- [x] Reapply minimal first-scene bootstrap + abort-aware wait from T1619 in offline CFR renderer.
- [x] Re-verify build and focused teaser suites.
- [x] Roll back strict T1619 reapply (timeout-abort path) and restore renderer baseline.
- [x] Add surgical canvas-source fallback for teaser capture (active layer fallback chain).

## Code Change Ledger
- [x] Created troubleshooting task tracker file only: `tasks/active/T1623_troubleshoot_teaser_regression_post_banner_changes.md`.
- [x] Rolled back teaser marketing-overlay edits using git restore:
  - `src/systems/TeaserRecorderHud.res`
  - `src/systems/TeaserRecorder.res`
  - `src/systems/TeaserOfflineCfrRenderer.res`
- [x] Kept export-side marketing changes untouched:
  - `src/systems/Exporter/ExporterPackaging.res`
  - `src/systems/TourTemplates.res`
  - `src/systems/TourTemplates/TourStyles.res`
- [x] Reapplied targeted teaser stabilization:
  - `src/systems/TeaserOfflineCfrRenderer.res`
  - Added `isViewerOnScene`, `waitForViewerReadyOrAbort`, `forceLoadSceneAndWait`
  - Added first-shot bootstrap before frame loop and replaced in-loop scene waits with abort-aware force-load
  - Revert note: remove helper trio/bootstrap and restore `Playback.waitForViewerReady` usage.
- [x] Reverted strict reapply by restoring `src/systems/TeaserOfflineCfrRenderer.res` from `be11c8dd`.
- [x] Added capture robustness fallback:
  - `src/systems/TeaserRecorder.res`: introduced `resolveSourceCanvas()` with fallback chain:
    1) `.panorama-layer.active canvas`
    2) `.panorama-layer canvas`
    3) `.pnlm-render-container canvas`
  - Updated `startAnimationLoop` to use `resolveSourceCanvas`.
  - Exported `resolveSourceCanvas` from `Recorder` module.
  - `src/systems/TeaserOfflineCfrRenderer.res`: replaced direct selector query with `Recorder.resolveSourceCanvas()`.

## Rollback Check
- [ ] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
We are troubleshooting teaser breakage reported after banner/export edits.  
Current branch has many unrelated dirty files; investigation must isolate teaser-specific deltas only.  
Primary comparison target is current working tree versus `be11c8dd` for teaser modules and shared dependencies.

## Findings (Current)
- HEAD is `be11c8dd` (`v4.14.2+2 [FAST]: Stable workable`).
- No teaser file changes were committed between `ddca6057` and `be11c8dd`.
- Current teaser regressions map to uncommitted working-tree edits in:
  - `src/systems/TeaserRecorderHud.res`
  - `src/systems/TeaserRecorder.res`
  - `src/systems/TeaserOfflineCfrRenderer.res`
- Delta introduced marketing banner render path into teaser overlay draw loop.
- Surgical rollback was completed, then minimal T1619 first-scene stabilization was reapplied.
- Focused verification passed:
  - `tests/unit/TeaserRecorder_v.test.bs.js`
  - `tests/unit/TeaserManager_v.test.bs.js`
  - `tests/unit/ServerTeaser_v.test.bs.js`
  - `npm run build`
