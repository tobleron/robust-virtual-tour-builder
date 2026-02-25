# 1546 — Standardize Hotspot Delete Flow (Consistency Fix)

## Priority: P1 — UX Consistency

## Objective
Make hotspot deletion behavior consistent between `HotspotActionMenu.res` and `PreviewArrow.res`.

## Context
Two code paths exist for deleting hotspots, with different behaviors:

| Path | Component | Behavior |
|------|-----------|----------|
| Hover menu (far bottom) | `PreviewArrow.res` line 198 | Red flicker → immediate delete, NO confirmation, NO undo |
| Action menu (panel) | `HotspotActionMenu.res` line 37 | Confirmation modal ("Delete Link" / "Are you sure?") → then delete, NO undo |

This creates an inconsistent experience. The inline hover delete is faster but has no safety net. The action menu delete is slower (modal) but also has no undo.

## Recommended Approach
Since scene deletion successfully uses the undo-notification pattern (no confirmation modal, 9s undo window), apply the same pattern to hotspot deletion:

1. Remove the confirmation modal from `HotspotActionMenu.res`
2. Both paths: 800ms flicker → delete → 9s undo notification with "U" shortcut
3. Use `StateSnapshot.capture()` / `rollback()` pattern (same as scene delete)

## Acceptance Criteria
- [ ] `PreviewArrow.res` delete: shows "Link deleted. Press U to undo." notification with 9s timer
- [ ] `HotspotActionMenu.res` delete: same notification, no confirmation modal
- [ ] Undo restores the hotspot and its timeline entry
- [ ] Backend sync delayed 9.5s (only fires if undo not triggered)
- [ ] Builds cleanly

## Files to Modify
- `src/components/PreviewArrow.res` — add undo notification to `handleDeleteClick`
- `src/components/HotspotActionMenu.res` — remove confirmation modal, add undo notification
- `src/components/Sidebar/SidebarLogicHandler.res` — reference for undo pattern (lines 667-736)
