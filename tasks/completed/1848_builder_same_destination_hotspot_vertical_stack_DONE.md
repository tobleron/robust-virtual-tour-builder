# 1848 Builder Same-Destination Hotspot Vertical Stack

## Objective
When multiple builder hotspots in the same source scene target the same destination scene, make the duplicate hotspots render as a vertical stack under the first hotspot and suppress the duplicate room labels above the repeated entries.

## Scope
- Builder hotspot overlay behavior only.
- No export/runtime hotspot behavior changes.
- No scene traversal or numbering changes.

## Acceptance Criteria
- The first hotspot to a destination scene remains the visible anchor position.
- The second, third, and later hotspots to that same destination render vertically below the anchor hotspot.
- Only the anchor hotspot keeps the destination room label above it.
- Duplicate stacking does not change exported-tour hotspot merge logic.
- `npm run build` succeeds.

## Notes
- Prefer applying the stacking in the builder hotspot overlay layer so same-destination authored links stay intact in project data.
- Keep the implementation compatible with existing move/retarget controls.

## Implementation Notes
- Use the first hotspot targeting a destination scene as the visual anchor.
- Render later hotspots to that same destination at the anchor x-position with fixed vertical spacing below it.
- Keep duplicate room labels hidden so only the anchor hotspot names the destination.
- Preserve authored hotspot data; do not alter export/runtime merge logic.

## Verification
- `npm run res:build`
- `npx vitest run tests/unit/ReactHotspotLayer_v.test.bs.js`
- `npm run test:frontend`
- `npm run build`
