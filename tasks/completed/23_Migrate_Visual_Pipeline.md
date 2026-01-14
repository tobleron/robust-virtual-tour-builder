# Task: Migrate Visual Pipeline to ReScript

## Objective
Convert the `VisualPipelineComponent.js` into a native ReScript component (using React or direct DOM manipulation as needed).

## Context
The Visual Pipeline handles the timeline drag-and-drop. It's currently one of the last major UI chunks in JS.

## Implementation Steps

1. **Create `VisualPipeline.res`**:
   - Port the rendering logic for the timeline nodes.
   - Implement the Drag-and-Drop logic using the HTML5 Drag API or a ReScript binding.

2. **State Integration**:
   - Use `GlobalStateBridge.getState().timeline` as the source of truth.
   - Dispatch `ReorderTimeline(from, to)` actions.

3. **Styling**:
   - Move styles from `pipeline.css` into the component or use Tailwind classes.

## Testing Checklist
- [x] Dragging items to reorder updates the state.
- [x] Clicking a node activates that scene/step.
- [x] Timeline correctly highlights the active step.

## Definition of Done
- `VisualPipelineComponent.js` is deleted.
- Timeline is fully functional in ReScript.
