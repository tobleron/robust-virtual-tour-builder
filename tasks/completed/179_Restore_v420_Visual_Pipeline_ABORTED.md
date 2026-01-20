# Task: Restore v4.2.0 Visual Pipeline

## Description
Restore the Visual Pipeline (Timeline) at the bottom center of the screen, ensuring it matches the v4.2.0 layout and interaction model.

## Key Features (v4.2.0 Points 43-52)
1. **Bottom-Center Anchor**: Position the pipeline container at the absolute bottom center, ensuring it is properly layered below other HUD elements.
2. **Margin Safety Padding**: Apply `padding-left: 100px` to the container to ensure it doesn't overlap with the floor navigation buttons.
3. **32px Node Standard**: Standardize pipeline nodes to 32px circles.
4. **4px Connecting Pipes**: Restore the "pipe" visualization with a 4px stroke width between nodes.
5. **Dynamic Color Sync**: Nodes and pipes must inherit the group color of their associated scene.
6. **Active State Highlighting**: Implement the white 3px border ring on the active timeline step.
7. **Hover Scale Interaction**: Nodes should scale to `1.15x` on hover with a smooth transition.
8. **Tooltip Thumbnail Previews**: Restore the 112px cached thumbnail preview on node hover.
9. **Interactive Drop Zones**: Implement the expanding drop zones between nodes to facilitate drag-and-drop reordering.
10. **Empty State Logic**: Hide the pipeline container if no timeline steps exist.

## Implementation Details
- Target Files: `VisualPipeline.res`, `style.css`
- Reference Commit: `49f727a`
