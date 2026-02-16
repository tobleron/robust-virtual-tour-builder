# T1419 - Troubleshoot Export Hotspot Target Resolution Regression

## Objective
Fix exported-tour hotspot click navigation regression where clicking a hotspot throws "No panorama image was specified" instead of transitioning to the linked scene.

## Hypotheses (Expected Solutions Ordered by Probability)
- [x] **H1 (Highest)**: Export runtime calls `viewer.loadScene(...)` with an unresolved/invalid target scene id due weak `createTooltipArgs` target normalization.
- [x] **H2**: Hotspot click handler resolves stale/partial args during runtime, causing empty target ids in some transition paths.
- [x] **H3**: Some exported hotspots lack valid `target` payload and require defensive fallback validation before scene load.

## Activity Log (Experiments / Edits)
- [x] Inspect `src/systems/TourTemplates.res` hotspot click-to-navigation flow (`createTooltipArgs`, `resolveTargetSceneId`, `navigateToNextScene`).
- [x] Add strict target-scene resolution + validation against exported `scenesData`/`config.scenes` before `loadScene`.
- [x] Add defensive target normalization in tooltip args and runtime click path.
- [x] Verify with `npm run build`.

## Code Change Ledger (for Surgical Revert)
- [x] `src/systems/TourTemplates.res` - Hardened navigation target resolution with `normalizeSceneId`, `hasExportScene`, and validated `resolveTargetSceneId(..., forceTargetSceneId)` before `loadScene`; added defensive tooltip arg `target` alongside `targetSceneId`; added `data-target-scene-id` caching on hotspot root. Revert path: remove these helpers/args and restore previous direct `loadScene(forceTargetSceneId ?? resolveTargetSceneId(args), ...)` path.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes before completion move.

## Context Handoff
- [x] Document root cause and the exact runtime guard added.
- [x] Note any residual edge-case requiring future follow-up.
- [x] Record build/test verification status.
