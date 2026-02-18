# T1464 - Troubleshoot: Auto-forward toggle sometimes requires two clicks to visually stick

## Objective
- Fix intermittent builder issue where toggling a hotspot to auto-forward (double-chevron) needs a second click before visual state updates.
- Ensure first click reliably updates hotspot icon state and persisted metadata.
- Preserve current behavior where export/runtime use explicit hotspot-level auto-forward only.

## Scenario Reported
- In stage/builder viewer, clicking auto-forward toggle sometimes does not visually apply on first attempt.
- Second click often makes the visual state correct.

## Scope
- `PreviewArrow` right-button toggle path.
- `HotspotActionMenu` toggle path.
- Reducer + hotspot sync timing (`UpdateHotspotMetadata`, `ForceHotspotSync`, hotspot re-render lifecycle).

## Hypothesis (Ordered Expected Solutions)
- [x] Toggle handler computes `newVal` from stale hotspot snapshot instead of latest local/rendered value, causing no-op writes on first click.
- [x] `ForceHotspotSync` is dispatched before updated state is fully observed by hotspot rendering side effects, creating a visual race.
- [x] Pointer/click dual-handler or debounce lock interaction in export/builder arrow controls causes first interaction to be swallowed.
- [x] State sync effect in `PreviewArrow` (`useEffect` on structural revision) overwrites optimistic local toggle with stale value briefly.

## Activity Log
- [x] Created troubleshooting task file in `tasks/active`.
- [x] Audit toggle handlers and state source of truth for `newVal`.
- [x] Audit hotspot sync event ordering around `ForceHotspotSync`.
- [x] Implement deterministic first-click toggle logic.
- [x] Add/adjust tests for first-click correctness.
- [x] Run targeted tests and full build.

## Code Change Ledger
- [x] `src/components/HotspotActionMenu.res`: Derived `isAutoForward` from live app state (`sceneIndex + hotspot index`) instead of stale menu payload snapshot; deferred `ForceHotspotSync` to next tick.
- [x] `src/components/PreviewArrow.res`: Toggle now computes from current local UI state, adds in-flight guard to prevent overlapping toggles, and defers forced sync to next tick.
- [x] `src/components/ViewerManagerLogic.res`: `ForceHotspotSync` handling moved to `requestAnimationFrame` callback so sync runs after state commit window, reducing stale-state races.
- [x] Validation: `tests/unit/PreviewArrow_v.test.bs.js`, `tests/unit/HotspotActionMenu_v.test.bs.js`, `tests/unit/HotspotManager_v.test.bs.js`, `tests/unit/TourTemplates_v.test.bs.js`, and full `npm run build`.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
Root cause was a race between immediate forced hotspot sync and state commit plus stale hotspot snapshots in interactive UI paths. The toggle now uses current local/live state and force-sync executes on next frame/tick to avoid stale re-render. Result should be deterministic first-click visual application of auto-forward in builder.
