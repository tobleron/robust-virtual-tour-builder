# T1416 Troubleshoot Export Logo, Hotspot Parity, and Toggle Logic

## Objective
Resolve three issues: exported tour logo is broken, exported hotspot visuals do not match builder behavior (including forward vs auto-forward icon selection), and UI requires setting forward/auto-forward twice before it persists.

## Hypothesis (Ordered Expected Solutions)
1. [x] **Highest probability**: Fix stale-state toggle flow in hotspot action UI so `isAutoForward` is computed from fresh state at click time and saved without stale closure state.
2. [x] Fix export logo resolution by normalizing logo filename/extension and ensuring URL-based logos are fetched and bundled under `assets/logo.*`.
3. [x] Fix export hotspot visual parity by serializing target scene auto-forward mode and rendering the matching forward/auto-forward icon style in exported runtime.

## Activity Log
- [x] Read architecture/task context docs (`MAP.md`, `DATA_FLOW.md`, `tasks/TASKS.md`).
- [x] Locate logo serialization + export packaging path resolution and identify break point.
- [x] Locate hotspot style serialization and exported runtime rendering path; compare builder/runtime mapping.
- [x] Reproduce and trace forward/auto-forward double-set behavior through UI -> action -> reducer -> persistence.
- [x] Implement fixes for logo export pathing.
- [x] Implement fixes for hotspot style parity (forward vs auto-forward) in exported runtime.
- [x] Implement fix for single-click persistence of forward/auto-forward toggle.
- [x] Verify `npm run build` passes.
- [x] Verify targeted behavior by static inspection and, where possible, test/runtime validation.
- [x] Align exported hotspot visuals to boxed button style parity with builder (single vs double chevron variants).
- [x] Remove remaining stale-state toggle path in `PreviewArrow` and force immediate hotspot re-sync after toggle.
- [x] Port builder hotspot button visual language (boxed button + diagonal sweep + hover treatment + chevron glyphs) into exported runtime template.
- [x] Diagnose broken exported logo byte/type mismatch path (empty persisted logo URL packaged as invalid `logo.png`) and harden export fallback behavior.
- [x] Diagnose/patch HTML-as-image false positive path in fallback logo fetch (`images/logo.*` relative route returning 200 non-image payload).

## Code Change Ledger (for Surgical Revert)
- [x] `src/components/HotspotActionMenu.res`: Toggle now reads fresh state from `AppContext.getBridgeState()` and saves `isAutoForward` without stale `~getState` override.
Revert note: restore previous `targetSceneOpt/ts`-based toggle block if needed.
- [x] `src/systems/Exporter.res`: Added `normalizeLogoExtension` + `filenameFromUrl`; export now fetches `Url` logos and includes them as `logo.<ext>`; export index call now passes `logoFilename`.
Revert note: remove helper functions and restore old `Some(Url(_u)) => ()` behavior and 2-arg `generateExportIndex` call.
- [x] `src/systems/TourTemplates.res`: Export index template changed to `__LOGO_BLOCK__` with dynamic filename; `generateExportIndex` signature now includes `logoFilename`.
Revert note: restore hardcoded `tour_4k/assets/logo.png` block and 2-arg function signature.
- [x] `src/systems/TourTemplates.res`: Export hotspot payload now includes `targetIsAutoForward`; runtime renderer draws single-chevron for manual and double-chevron for auto-forward.
Revert note: remove `targetIsAutoForward` field/encoding/args and restore prior single-chevron-only drawing block.
- [x] `src/systems/TourTemplates.res`: Updated exported hotspot CSS/renderer from large perspective chevron to boxed icon button visuals to match builder UI.
Revert note: restore previous `custom-arrow-svg` perspective transform and old chevron path rendering.
- [x] `src/systems/TourTemplates.res`: Added export-side animation classes/keyframes (`diagonal-sweep`) and button layer structure to mirror builder hotspot button effects.
Revert note: remove `export-hotspot-*` classes/keyframes and restore legacy static hotspot markup.
- [x] `src/systems/Exporter.res`: Added invalid URL guard for logo (`""` or non-image-looking URL), skipped unsafe URL-logo fetches, and centralized default-logo fallback when no valid logo is attached.
Revert note: restore prior logo `Url` fetch branch and fallback behavior limited to `logo=None`.
- [x] `src/core/JsonParsersDecoders.res`: Added `normalizeLogo` to convert persisted `Some(Url(\"\"))` into `None` so broken placeholder URL does not propagate into export.
Revert note: remove `normalizeLogo` helper and restore direct decoded logo assignment.
- [x] `src/systems/Exporter.res`: Switched fallback logo fetch path to absolute `/images/logo.*`; added blob MIME/url-hint validation so non-image payloads are rejected before packaging.
Revert note: restore relative `images/logo.*` fetch and remove `isLikelyImageBlob` validation branch.
- [x] `src/components/PreviewArrow.res`: Toggle now resolves target scene from fresh bridge state and dispatches `ForceHotspotSync` after metadata update to avoid first-click visual lag.
Revert note: restore prior `targetSceneRef` memo/useEffect synchronization and remove forced hotspot sync dispatch.
- [x] `tests/unit/TourTemplateAssets_v.test.res`, `tests/unit/TourTemplates_v.test.res`: Updated calls to `generateExportIndex(..., None)` for new signature.
Revert note: if signature reverts to 2 args, revert these test callsites accordingly.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
This task tracks export/runtime parity and toggle persistence defects end-to-end across builder state, project serialization, and exported runtime rendering. Continue by following the three symptom tracks independently, then validate they converge in one coherent persisted model for hotspot button mode and logo references. If session context fills, resume from the Activity Log checkboxes and keep this file as the single source of troubleshooting progress.
