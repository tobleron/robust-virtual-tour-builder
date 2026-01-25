# Task 539: Performance Optimization - SVG Element Reuse

## Objective
The most significant impact on "stutter" reduction: prevent the repeated destruction and recreation of the entire SVG overlay (DOM nodes) during every camera movement.

## 🛠 Strategic Implementation (Safety First)
- **Reference**: `src/systems/HotspotLine.res`.
- **Action**: Instead of `Dom.setTextContent(svg, "")`, implement a mechanism to track existing `<path>` elements.
- **Action**: Update the `d` attribute of existing paths instead of appending new ones.
- **Action**: Hide (e.g., `display: none`) excess paths if the number of lines decreases.

## 🛡 Stability Considerations
- **Garbage Collection**: Use a simple "pool" or clear the SVG only on SCENE CHANGE, but keep it persistent during intra-scene navigation.
- **ID Management**: Ensure lines are mapped correctly so that Path A doesn't accidentally jump to Path B's coordinates.
- **Performance Threshold**: Massive performance gain expected here, but must handle the edge case where no hotspots exist in a scene.

## ✅ Success Criteria
- [ ] `updateLines` in `HotspotLine.res` no longer clears the SVG on every move.
- [ ] Stuttering during panning is visibly reduced.
- [ ] Scene transitions correctly reset the SVG state.
- [ ] Build passes (`npm run build`).
