# 1543 — Fix Auto-Forward One-Per-Scene Guard in PreviewArrow.res

## Priority: P0 — Logic Bug

## Objective
Add the one-per-scene auto-forward validation to `PreviewArrow.res` `handleRightClick`, matching the guard already present in `HotspotActionMenu.res`.

## Context
`HotspotActionMenu.res` (lines 90-138) correctly validates that only one auto-forward link exists per scene before toggling. However, `PreviewArrow.res` `handleRightClick` (lines 132-173) dispatches `UpdateHotspotMetadata` without this check, allowing users to enable multiple auto-forward links via the inline hover button.

## Acceptance Criteria
- [ ] `PreviewArrow.res` `handleRightClick` checks existing auto-forward count on the current scene before enabling
- [ ] If another auto-forward link exists, show error notification: "Only one auto-forward link per scene"
- [ ] If the user is DISABLING auto-forward (toggling off), the check should NOT block the action
- [ ] Builds cleanly (`npm run build`)

## Implementation Guide
1. Open `src/components/PreviewArrow.res`
2. In `handleRightClick` (around line 142), before dispatching `UpdateHotspotMetadata`:
   - Get current scene's hotspots from `AppContext.getBridgeState()`
   - Count hotspots where `isAutoForward == Some(true)` (excluding the current hotspot)
   - If count > 0 AND `newVal == true` (trying to enable), show error notification and return
3. Reuse the same error toast format from `HotspotActionMenu.res` line 126-138

## Files to Modify
- `src/components/PreviewArrow.res` (single file change)

## Testing
- Manually test: Create 2 links on one scene, enable auto-forward on first, try to enable on second via hover button → should show error
- Existing E2E test `auto-forward-comprehensive.spec.ts` should continue passing
