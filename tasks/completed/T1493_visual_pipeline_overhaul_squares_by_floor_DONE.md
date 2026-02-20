# T1493: Visual Pipeline Overhaul - Scalable Squares by Floor

## 🎯 Objective
Refactor the Visual Pipeline (the thumbnail sequence at the bottom of the viewer) to improve scalability when dealing with many links (>100). Replace thumbnails with small, color-coded squares and organize them into vertical rows based on which floor they belong to.

## 🛠️ Requirements

### 1. Visual Node Transformation
- **Shape Change**: Replace the current 44x30px rectangular thumbnails in `.pipeline-node` with small squares (**12x12px**).
- **Styling**:
    - The square must be filled with the color currently used for the border (derived from `ColorPalette.getGroupColor(s.colorGroup)` or `#4B0082` for auto-forward).
    - Apply rounded corners (e.g., `border-radius: 3px`).
    - **Remove/Deprecate** the `.pipeline-badge` (scene number) to reduce visual clutter.
- **Hover State**:
    - On hover, the node should trigger the existing tooltip/preview logic.
    - Ensure the user can still see the high-quality thumbnail preview in the tooltip as they do now.

### 2. Vertical Floor-Based Layout
- **Grouping**: Group timeline items into distinct horizontal tracks (rows) based on the **floor** of the linked scene.
- **Ordering**:
    - Cross-floor links (e.g., *Ground Floor → First Floor*) remain on the **source floor's row** at the very end of it.
    - Rows should be vertically ordered: **Highest floors at the top**, lower floors below.
- **UI Logic**:
    - The collection of tracks should remain centered at the bottom of the viewer stage.
    - Implement the logic in `VisualPipeline.res` to split the `timeline` into groups by floor before rendering.

### 3. Stylistic "Electronic Board" Lines
- **Feature**: Add thin orange stylistic lines connecting each floor's representation (likely the floor navigation area on the left) to the first square of its corresponding row.
- **Style**: "Electronic board adapted lines" (orthogonal paths with 90/45 degree angles, not smooth curves).
- **Condition**: These lines should only appear when a row has at least one square.
- **Color**: Use the brand orange (`var(--orange-brand, #f97316)`).

### 4. Responsive & Stylistic Adjustments
- **Container**: Ensure `#visual-pipeline-container` and `.visual-pipeline-wrapper` handle multiple rows gracefully without overlapping other HUD elements (UtilityBar, etc.).
- **Transitions**: Maintain smooth transitions for active states and hover effects.

## 📂 Critical Files
- `src/components/VisualPipeline.res`: Core component logic and rendering.
- `src/components/VisualPipelineLogic.res`: CSS-in-JS styles and layout definitions.
- `src/components/FloorNavigation.res`: Source point for floor identification.
- `src/core/Types.res`: `scene` and `timelineItem` definitions.

## 🧪 Verification Plan
- [ ] Create 10+ scenes spread across at least 2 floors.
- [ ] Create links within the same floor and links across floors.
- [ ] Verify that cross-floor links appear at the end of the source floor row.
- [ ] Verify that nodes are 12x12px squares filled with color.
- [ ] Verify "Electronic Board" orange lines connect floors to their respective tracks.
- [ ] Verify that hover still shows tooltip thumbnails.
- [ ] Test with a large number of links to ensure no overlap with other UI components.
