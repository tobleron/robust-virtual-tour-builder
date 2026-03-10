# T1824 Troubleshoot 059 Untagged Selection Hang

## Hypothesis (Ordered Expected Solutions)
- [ ] The `059_Untagged` scene payload contains malformed or unusually heavy hotspot/view data that causes selection/navigation work to stall.
- [ ] Selecting `059_Untagged` triggers a scene-specific navigation or viewer load edge case, such as a bad asset path, broken tiny file, or invalid arrival view.
- [ ] The hang is caused by scene-list or label-derived UI work specific to untagged scenes rather than the scene payload itself.

## Activity Log
- [x] Read `MAP.md`, `DATA_FLOW.md`, `tasks/TASKS.md`, `.agent/workflows/rescript-standards.md`, and `.agent/workflows/debug-standards.md`.
- [x] Located scene selection flow in `src/components/SceneList/SceneItem.res`, `src/components/SceneList.res`, and navigation/viewer orchestration docs.
- [x] Confirmed multiple stored projects contain `059_Untagged.webp`, so this is likely data-specific rather than a generic label-only issue.
- [x] Inspect actual `059_Untagged` payload and references for anomalies.
- [x] Reproduce the failure on a duplicate of the exact `Kamel_Al_Kilany_080326_1528` snapshot family under `dev_user_id/080326-debug-copy`.
- [x] Narrow the failing path to builder preload normalization: `059_Untagged` in the failing snapshot retained bare filename refs while neighboring scenes had normalized `/api/project/.../file/...` URLs.
- [x] Verify the builder preload normalization fix against the duplicate repro and normal build.

## Code Change Ledger
- [x] `src/site/PageFrameworkBuilder.js` - Added scene asset URL normalization during builder preload for `inventory` and `scenes` payloads, not just `logo`. Revert by removing `normalizeSceneFileForBuilder` / `normalizeInventoryForBuilder` and restoring `normalizeProjectDataForBuilder`.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
- The issue reproduced cleanly only on the `Kamel_Al_Kilany_080326_1528` snapshot family, not on a different normalized Kamel duplicate. The failing snapshot had a mixed asset-path shape where `059_Untagged` still carried bare filename refs while builder preload only normalized `logo`, so navigation to `059` stalled in `Preloading` because the scene asset URL was never rebuilt. The fix was applied in `src/site/PageFrameworkBuilder.js`, and the duplicate repro now transitions `059_Untagged` successfully back to `IdleFsm`.
