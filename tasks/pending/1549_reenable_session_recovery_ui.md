# 1549 — Re-enable Session Recovery UI (Auto-Save Restore Prompt)

## Priority: P2 — Missing Feature

## Objective
Uncomment and activate the "Unsaved Session Found" recovery modal in `Main.res` so that users can restore auto-saved data after a page refresh or crash.

## Context
`PersistenceLayer.res` actively auto-saves project state to IndexedDB (`autosave_session_latest` key, 2s debounce, schema v2). `checkRecovery()` is called on startup and successfully retrieves saved data. However, the modal UI that asks "Unsaved Session Found — Restore or Discard?" is entirely commented out in `Main.res` lines 203-262. This was intentionally disabled during development but should now be re-enabled.

## Current Code (Commented Out)
```rescript
// Main.res lines 203-262
/*
switch recovered {
| Some(session) =>
  EventBus.dispatch(ShowModal({
    title: "Unsaved Session Found",
    description: Some("We found an unsaved session from " ++ dateStr ++ "..."),
    buttons: [
      { label: "Restore", onClick: () => { ... LoadProject ... } },
      { label: "Discard", onClick: () => { ... clearSession ... } },
    ],
  }))
| None => ()
}
*/
```

## Acceptance Criteria
- [ ] Uncomment the recovery modal code in `Main.res`
- [ ] Wire `checkRecovery()` result into the modal display
- [ ] Modal shows the timestamp of the saved session formatted as a locale string
- [ ] "Restore" button loads the saved project data and shows success notification
- [ ] "Discard" button clears the IndexedDB session and shows dismissal notification
- [ ] If no saved session exists, nothing happens (no modal)
- [ ] Test: Create a project with scenes → refresh page → recovery modal should appear
- [ ] Test: Click "Restore" → previous project state restored
- [ ] Test: Click "Discard" → fresh empty state
- [ ] Builds cleanly

## Implementation Notes
- The `PersistenceLayer.checkRecovery()` call is already in `Main.res` line 200. It returns `Promise<Option<serializedSession>>`.
- The commented code is almost complete. Main work is uncommenting + testing + handling edge cases (e.g., recovery during an active session).
- Consider: Should recovery prompt appear if the user already has an active project? Maybe only show if current state is empty (no scenes loaded).

## Files to Modify
- `src/Main.res` (primary — uncomment and wire recovery modal)
- Potentially `src/utils/PersistenceLayer.res` (if edge cases need handling)
