# 1551 — Add Unsaved Changes Warning on Browser Close/Refresh

## Priority: P3 — Safety Net

## Objective
Add a `beforeunload` confirmation dialog that warns the user when they try to close or refresh the browser with unsaved project changes.

## Context
`PersistenceLayer.res` already has a `beforeunload` listener that flushes the operation journal and performs a pending auto-save. However, it does NOT trigger the browser's native "Are you sure you want to leave?" confirmation dialog.

While auto-save mitigates data loss, the recovery UI is currently disabled (see task 1549). Until recovery is re-enabled, users who refresh will lose their work silently.

## Implementation Guide
The `beforeunload` handler in `PersistenceLayer.res` line 135-143 should additionally call `event.preventDefault()` and set `event.returnValue = ""` when there are unsaved changes:

```rescript
let listener = event => {
  OperationJournal.flushAllInFlight()
  
  let state = stateGetterRef.contents()
  let hasContent = Array.length(SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)) > 0
  
  if hasContent {
    // Trigger browser's native confirmation dialog
    DomBindings.Event.preventDefault(event)
    DomBindings.Event.setReturnValue(event, "")
  }
  
  switch lastSaveTimeout.contents {
  | Some(_) => performSave(state)
  | None => ()
  }
}
```

## Acceptance Criteria
- [ ] Browser shows native "Leave site?" dialog when user has scenes loaded and tries to close/refresh
- [ ] Dialog does NOT appear on empty state (no scenes)
- [ ] Auto-save still flushes before the dialog appears
- [ ] No interference with normal navigation (internal route changes)
- [ ] Builds cleanly

## Files to Modify
- `src/utils/PersistenceLayer.res` (single file change)
- Potentially `src/bindings/DomBindings.res` if `preventDefault` / `returnValue` setters are missing
