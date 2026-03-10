# T1826 Troubleshoot Export Sequence Arrows And Dead-End Camera Behavior

## Hypothesis (Ordered Expected Solutions)
- [ ] The export glass-panel `ArrowDown` currently uses visit history (`persistentFrom`) instead of canonical sequence order, so previous-scene navigation diverges from the authored traversal sequence.
- [ ] Dead-end scenes should suppress the redundant backward arrow when the canonical next action is already the return/exit path, and this can be fixed in export shortcut-panel state derivation without changing builder behavior.
- [ ] Revisited scenes already skip full animation correctly, but exported tours need a post-arrival orientation policy that always aligns the camera toward the next canonical hotspot, or for dead ends settles at the waypoint terminal view and then pans horizontally toward the exit.
- [ ] The export runtime is selecting “next hotspot” statelessly instead of based on real visited-path history, so revisiting a hub after a dead-end branch can incorrectly point back to the branch just taken.
- [ ] Dead-end arrival should start from an entry-opposite yaw, then pan horizontally toward the exit, which is more coherent than snapping directly to the exit-facing view.

## Activity Log
- [x] Read `MAP.md`, `DATA_FLOW.md`, `tasks/TASKS.md`, `.agent/workflows/debug-standards.md`, and `.agent/workflows/rescript-standards.md`.
- [x] Located export traversal and shortcut logic in `src/systems/TourTemplates/TourScriptNavigation.res`, `src/systems/TourTemplates/TourScriptUINav.res`, `src/systems/TourTemplates/TourScriptInput.res`, and `src/systems/TourTemplates/TourScriptHotspots.res`.
- [x] Implemented canonical previous-scene resolution for export shortcut panel and keyboard down-arrow handling.
- [x] Suppressed redundant backward arrow on dead-end scenes where the forward action is already the exit/return path.
- [x] Added exported-tour post-arrival orientation logic that preserves no-reanimation-on-revisit while steering toward the next canonical hotspot, or horizontally toward the exit for dead ends.
- [x] Added focused unit coverage in `tests/unit/TourTemplates_v.test.res`.
- [x] Verified `npm run res:build` and `npx vitest tests/unit/TourTemplates_v.test.bs.js --run`.
- [x] Identified the revisit regression source: export traversal was not using a true per-scene visited runtime, and hub re-entry could still resolve the just-visited branch again.
- [x] Switched export traversal to a visited-aware per-scene hotspot runtime, marking hotspots visited only when a real navigation occurs.
- [x] Routed export `ArrowUp` through the active canonical hotspot payload instead of bare scene-id navigation so the visited runtime stays consistent.
- [x] Changed dead-end arrival orientation to face 180 degrees opposite the entry/exit hotspot yaw, then pan horizontally back toward the exit.
- [x] Verified the updated generated `.bs.js` output contains the new visited-runtime and dead-end orientation logic while the background ReScript watcher is active.
- [x] Excluded return links from the canonical unvisited-forward pool so they are only used as explicit exit fallback, never counted as ordinary unvisited progression targets.
- [x] Compared the current export runtime against `HEAD` and identified the real regression source: generated tours still default to legacy traversal mode, but the legacy `__visited` playback reset had been removed.
- [x] Restored the legacy playback reset inside `resolveScenePlaybackHotspot(...)` so first-arrival animation selection no longer inherits stale return-link state across revisits.
- [x] Re-ran `npx vitest tests/unit/TourTemplates_v.test.bs.js --run` successfully and noted that `npm run res:build` was blocked only because an existing ReScript watcher process was already active.
- [x] Split export shortcut guidance away from playback selection so `ArrowUp` only uses a real next unvisited non-return hotspot and `ArrowDown` resolves through dead-end exit or previous sequence target.
- [x] Generalized re-entry orientation tracking to all hotspot-based navigations, so mouse hotspot clicks, `R`, and keyboard arrows share the same post-return pan behavior.
- [x] Re-ran `npm run res:build` and `npx vitest tests/unit/TourTemplates_v.test.bs.js --run` after the shared-navigation refinement.
- [x] Identified the deeper model mismatch: deduped visible export hotspots were still being used as progression state, so revisits like `5 -> ... -> 15` could not be represented once duplicate visible hotspots were collapsed.
- [x] Exported explicit per-scene logical `sequenceEdges` alongside visible `hotSpots`, then switched the export runtime to track a current scene sequence cursor and source scene instead of per-visible-hotspot visited flags.
- [x] Updated scene-load sequencing, label rendering, panel arrows, keyboard navigation, and visible hotspot clicks to resolve the next logical edge from `sequenceEdges` while keeping the UI deduped.
- [x] Re-ran `npm run res:build` and `npx vitest tests/unit/TourTemplates_v.test.bs.js --run` after the sequence-edge engine landed.
- [x] Added a post-arrival fallback hotspot resolver so exhausted hub scenes pan toward their return-link exit once all forward branch hotspots have been visited.
- [x] Re-ran `npx vitest tests/unit/TourTemplates_v.test.bs.js --run`, `npm run res:build`, and `npm run build` after the exhausted-hub fallback change.
- [x] Identified that scene animation state was only marked in `finalizeSceneArrival(...)`, which made interrupted first visits count as “not animated yet”.
- [x] Moved the one-time animated-scene mark to animation start so interrupted first visits are still treated as already animated on revisit.
- [x] Re-ran `npx vitest tests/unit/TourTemplates_v.test.bs.js --run`, `npm run res:build`, and `npm run build` after the interrupted-animation state fix.

## Code Change Ledger
- [x] `src/systems/TourTemplates/TourScriptNavigation.res`: added canonical previous-scene resolver and a shared dead-end predicate so export panel state no longer relies on visit history for the down-arrow.
- [x] `src/systems/TourTemplates/TourScriptUINav.res`: switched glass-panel backward navigation to canonical previous-scene resolution and suppressed the backward arrow when the current scene is a dead end whose forward action is already a return/exit.
- [x] `src/systems/TourTemplates/TourScriptCore.res`: extended waypoint runtime cleanup to cancel post-arrival orientation animations cleanly on scene changes.
- [x] `src/systems/TourTemplates/TourScriptHotspots.res`: added post-arrival orientation helpers so revisited scenes stay non-fully-animated while still steering toward the next hotspot, and dead ends snap to the terminal view then pan horizontally toward the exit.
- [x] `tests/unit/TourTemplates_v.test.res`: added regression assertions covering canonical previous-scene resolution, dead-end back-arrow suppression, and post-arrival orientation helpers in generated export HTML.
- [x] `src/systems/TourTemplates/TourScriptNavigation.res`: added a per-scene visited-hotspot runtime and moved canonical next-target selection off transient hotspot flags onto actual navigation history.
- [x] `src/systems/TourTemplates/TourScriptUIMap.res`: extended export shortcut state to retain the active canonical hotspot index.
- [x] `src/systems/TourTemplates/TourScriptUINav.res`: added `navigateToNextSequenceShortcut()` so panel `ArrowUp` uses the current canonical hotspot payload and marks real traversal correctly.
- [x] `src/systems/TourTemplates/TourScriptInput.res`: routed keyboard `ArrowUp` through the same canonical next-shortcut helper as the glass panel.
- [x] `src/systems/TourTemplates/TourScriptHotspots.res`: changed dead-end arrival from terminal-view snap to entry-opposite yaw plus horizontal pan toward the exit.
- [x] `src/systems/TourTemplates/TourScriptNavigation.res`: changed canonical next-target selection so return links are excluded from the unvisited-forward pool and only chosen as explicit fallback exits.
- [x] `tests/unit/TourTemplates_v.test.res`: added regression assertions that canonical traversal picks unvisited non-return hotspots first and treats return links as fallback only.
- [x] `src/systems/TourTemplates/TourScriptNavigation.res`: restored the legacy `hotspot.__visited` reset before playback-target selection so normal first-entry animation does not get replaced by return-link fallback behavior.
- [x] `tests/unit/TourTemplates_v.test.res`: added a regression assertion requiring the legacy playback reset to remain in generated export HTML.
- [x] `src/systems/TourTemplates/TourScriptNavigation.res`: added `resolveDeadEndExitHotspot(...)` and `resolvePreviousSequenceTarget(...)`, and broadened arrival-orientation tracking from return-link-only to all hotspot-based navigations.
- [x] `src/systems/TourTemplates/TourScriptUINav.res`: routed glass-panel `ArrowUp`/`ArrowDown` through shared next/previous sequence helpers and stored previous-hotspot metadata for dead-end exits.
- [x] `src/systems/TourTemplates/TourScriptInput.res`: routed keyboard `ArrowDown` through the same previous-sequence helper as the panel.
- [x] `src/systems/TourTemplates/TourScriptUIMap.res`: extended export shortcut state with previous-hotspot metadata and return-link flags.
- [x] `tests/unit/TourTemplates_v.test.res`: updated export-runtime assertions to cover the new next/previous sequence helpers and broadened arrival-orientation tracking.
- [x] `src/systems/TourTemplates/TourData.res`: added `sequenceEdges` to exported scene data so logical sequence edges survive visible-hotspot dedupe.
- [x] `src/systems/TourTemplateHtml.res`: now serializes both deduped visible `hotSpots` and full logical `sequenceEdges`, with each logical edge mapped to its representative visible hotspot.
- [x] `src/systems/TourTemplates/TourScripts.res`: applies pending sequence context on scene load before labels/shortcuts render.
- [x] `src/systems/TourTemplates/TourScriptNavigation.res`: replaced per-visible-hotspot visited tracking with a scene sequence cursor, visible-hotspot-to-edge resolution, and logical next-edge lookup.
- [x] `src/systems/TourTemplates/TourScriptUINav.res`: labels, up-arrow, and down-arrow now resolve from sequence context instead of deduped hotspot visitation.
- [x] `src/systems/TourTemplates/TourScriptHotspots.res`: visible hotspot clicks now pick the best logical sequence edge for the current cursor, so revisits can act as `15 -> 16` even with one visible hotspot.
- [x] `src/systems/TourTemplates/TourScriptNavigation.res`: added `resolvePostArrivalFocusHotspot(...)` so revisit/no-animation arrivals fall back from next forward sequence edge to return-link exit or previous-target hotspot when the scene is exhausted.
- [x] `src/systems/TourTemplates/TourScriptHotspots.res`: switched revisit post-arrival pan targeting from `nextForwardHotspot` only to the shared `resolvePostArrivalFocusHotspot(...)` fallback.
- [x] `tests/unit/TourTemplates_v.test.res`: added a regression assertion requiring the generated export runtime to use `resolvePostArrivalFocusHotspot(...)` during revisit reorientation.
- [x] `src/systems/TourTemplates/TourScriptHotspots.res`: moved `animatedScenes.add(sceneId)` from arrival finalization to animation setup so interrupted first-entry animations still mark the scene as already animated.
- [x] `tests/unit/TourTemplates_v.test.res`: added a regression assertion requiring the generated export runtime to mark scenes as animated during animation setup.
- [x] Revised arrow-shortcut requirements: `ArrowUp` must follow the hotspot currently in front of the user, while `ArrowDown` must follow the came-from hotspot only when it is behind the user.
- [x] `src/systems/TourTemplates/TourScriptNavigation.res`: added current-yaw-facing shortcut resolution, hidden published-hotspot filtering, and a backward shortcut resolver that suppresses the source hotspot when it is in front of the user.
- [x] `src/systems/TourTemplates/TourScriptUINav.res`: rewired shortcut-panel state and up/down navigation handlers to resolve from current facing/source-behind targets instead of raw next/previous sequence picks.
- [x] `src/systems/TourTemplates/TourScriptHotspots.res`: refreshes shortcut-panel state after arrival and post-arrival pan completion so the glass-panel shortcuts match the final camera orientation.
- [x] `tests/unit/TourTemplates_v.test.res`: added regression assertions for facing-based forward resolution, source-behind backward resolution, and post-animation shortcut refresh.
- [x] Reworked export shortcut target resolution to be viewer-facing-based instead of purely sequence-next/sequence-prev.
- [x] Re-verified `TourTemplates` unit coverage and production build after the arrow-facing resolver change.
- [x] Reverted the viewer-facing arrow-shortcut experiment from `TourScriptNavigation.res`, `TourScriptUINav.res`, `TourScriptHotspots.res`, and `TourTemplates_v.test.res` after it broke export navigation behavior.
- [x] Restored the prior stable sequence-based up/down shortcut logic and queued a cleaner redesign later if needed.
- [x] Re-verified the restored export runtime with `TourTemplates` unit coverage and a production web build.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
- Export generation is back on the previously stable sequence-based shortcut model after reverting the failed viewer-facing arrow experiment.
- A future redesign for arrow semantics should come from a shared “active guidance target” model rather than patching panel state directly from current viewer yaw.
- Current priority is correctness: keep the restored navigation stable, then revisit smarter arrow semantics only with fresh export artifact validation.
