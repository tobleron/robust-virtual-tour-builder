# 1891 Contextual Hotspot Sequence Picker

## Objective
Change the hotspot `#` sequence editor so it only offers the immediate neighboring insertion choices around the currently selected hotspot occurrence, while keeping the underlying sequence as a global dense project-wide order.

## Scope
- Limit the visible sequence choices in the hotspot retarget/edit flow to the nearest valid neighbors around the active hotspot occurrence.
- Keep global renumbering behavior intact so inserting or removing a hotspot still shifts all downstream sequence values across the project.
- Treat repeated appearances of the same scene as separate sequence occurrences when deriving the picker context.
- Keep target selection and hotspot geometry unchanged.

## Acceptance Criteria
- The sequence picker no longer shows the full project order.
- When editing a hotspot in the middle of the order, the picker only exposes the adjacent surrounding choices.
- If the hotspot occurrence is at the start or end of the global order, the picker only shows the available one-sided choice.
- Repeated visits to the same scene remain independent sequence occurrences and do not collapse into one shared picker context.
- Saving an insertion or removal still renumbers all affected downstream hotspots globally.

## Verification
- `npm run build`
- Manual editor flow check for:
  - middle insertion
  - insertion at sequence start/end
  - repeated scene occurrence handling
  - removal compaction

## Notes
- The intended UX is contextual choice presentation, not local-only renumbering.
- The global ordering model stays unchanged; only the selection UI and its derivation logic change.
- This work primarily touches the hotspot edit UI and the sequence derivation/reorder helpers.

## Activity Log
- [x] Added contextual sequence helpers that return the current hotspot occurrence plus adjacent neighbors.
- [x] Switched the hotspot retarget modal to the contextual helper so it no longer exposes the full project sequence list.
- [x] Kept the global reorder engine intact so accepted sequence changes still renumber downstream hotspots across the project.
- [x] Verified the build with `npm run build`.
- [x] Replaced the retarget sequence dropdown with contextual radio-card choices and added clearer placement guidance.
- [x] Added modal styling for the contextual sequence picker.
- [x] Rebuilt successfully after the dialog UX rewrite.
- [x] Adjusted the link modal sizing so the new sequence picker no longer overflows the dialog.

## Dependencies
- Checkpoint commit `c97b2a07e` already captures the pre-implementation state.
