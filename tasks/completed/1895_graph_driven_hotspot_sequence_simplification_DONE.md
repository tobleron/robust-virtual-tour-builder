# 1895 Graph-Driven Hotspot Sequence Simplification

## Objective
Remove manual hotspot sequence editing from the builder and make hotspot numbering derive only from the current navigation graph, so inserting a missing middle scene by changing links automatically shifts numbering and removing a middle link compacts it again.

## Scope
- Remove manual `#` sequence selection from the link retarget dialog.
- Disable manual `sequenceOrder` overrides in traversal ordering.
- Make any remaining sequence UI read-only so the builder communicates that numbering is automatic.

## Acceptance Criteria
- Retargeting a hotspot only changes its destination, not a manual sequence override.
- Hotspot numbers are recalculated automatically from the current link graph.
- Adding a missing middle scene/hotspot causes downstream numbering to shift automatically.
- Removing a middle link/hotspot causes downstream numbering to compact automatically.
- Existing stored `sequenceOrder` values no longer affect displayed/exported traversal order.

## Verification
- Build the frontend bundle successfully.
- Confirm the retarget dialog no longer offers sequence editing.
- Confirm traversal ordering ignores manual `sequenceOrder` overrides.

## Status
- Implemented: manual sequence editing removed from the hotspot retarget dialog.
- Implemented: traversal ordering now ignores stored `sequenceOrder` overrides and follows the graph-derived order only.
- Implemented: hidden internal hotspot sequence edit path removed from the label menu stack.
- Verification completed with `npx rescript build` and `npx rsbuild build`.
