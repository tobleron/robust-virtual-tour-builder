# 1556 — Add Unit Test for Auto-Forward One-Per-Scene Validation

## Priority: P2 — Test Coverage

## Objective
Create a unit test that validates the auto-forward one-per-scene business rule, ensuring the validation logic is tested independently of the UI components.

## Context
The auto-forward validation exists in `HotspotActionMenu.res` (UI component), but there's no unit test for this business rule. After task 1543 adds the validation to `PreviewArrow.res` as well, having a shared validation function with a unit test would be ideal.

## Suggested Approach
1. Extract the auto-forward validation logic into a shared helper (e.g., `HotspotHelpers.canEnableAutoForward(scenes, sceneIndex, hotspotIndex): bool`)
2. Write unit tests for this helper
3. Both `PreviewArrow.res` and `HotspotActionMenu.res` call this helper

## Test Cases
- Scene with 0 auto-forward links → canEnable returns true
- Scene with 1 auto-forward link on a DIFFERENT hotspot → canEnable returns false
- Scene with 1 auto-forward link on THIS hotspot (disabling) → canEnable returns true (we're toggling off)
- Scene with 2+ hotspots, none auto-forward → canEnable returns true
- Empty scene (no hotspots) → canEnable returns true

## Acceptance Criteria
- [ ] Shared helper function `HotspotHelpers.canEnableAutoForward` created
- [ ] Unit test file `tests/unit/AutoForward_v.test.res` created with 5+ test cases
- [ ] Both `PreviewArrow.res` and `HotspotActionMenu.res` use the shared helper
- [ ] Tests pass (`npm test`)
- [ ] Builds cleanly

## Dependencies
- Should be done AFTER or TOGETHER WITH task 1543

## Files to Modify/Create
- `src/core/HotspotHelpers.res` — add `canEnableAutoForward`
- `tests/unit/AutoForward_v.test.res` — new test file
- `src/components/PreviewArrow.res` — use shared helper
- `src/components/HotspotActionMenu.res` — use shared helper
