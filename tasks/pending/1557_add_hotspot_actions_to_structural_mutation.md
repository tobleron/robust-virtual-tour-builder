# 1557 — Add CommitHotspotMove and UpdateHotspotMetadata to isStructuralMutation

## Priority: P0 — Data Loss Bug

## Objective
Add `CommitHotspotMove` and `UpdateHotspotMetadata` to the `isStructuralMutation` function in `Reducer.res` so that hotspot moves and metadata changes (e.g., auto-forward toggle) trigger auto-save.

## Context
**Critical finding from codebase review:** `Reducer.res` `isStructuralMutation` (lines 39-65) determines which actions increment `structuralRevision`, which in turn triggers `PersistenceLayer.res` to auto-save to IndexedDB.

Currently, these actions are **missing** from `isStructuralMutation`:
- `CommitHotspotMove(sceneIndex, hotspotIndex, yaw, pitch)` — moves a hotspot to a new position
- `UpdateHotspotMetadata(sceneIndex, hotspotIndex, metadata)` — toggles auto-forward, updates link properties
- `StartMovingHotspot` / `StopMovingHotspot` — transient (correctly excluded)

**Impact:** If a user:
1. Moves a hotspot → changes are NOT auto-saved
2. Toggles auto-forward → changes are NOT auto-saved
3. Refreshes the page → hotspot position and auto-forward state are LOST

## Fix
Add these two actions to the `isStructuralMutation` match:

```rescript
| Actions.UpdateHotspotMetadata(_, _, _)
| Actions.CommitHotspotMove(_, _, _, _) => true
```

## Acceptance Criteria
- [ ] `CommitHotspotMove` is in `isStructuralMutation` → triggers auto-save
- [ ] `UpdateHotspotMetadata` is in `isStructuralMutation` → triggers auto-save
- [ ] `StartMovingHotspot` and `StopMovingHotspot` remain excluded (transient state)
- [ ] Verify by: making a change, checking `structuralRevision` incremented, confirming IndexedDB write
- [ ] Builds cleanly

## Files to Modify
- `src/core/Reducer.res` (single line change, 2 actions added)
