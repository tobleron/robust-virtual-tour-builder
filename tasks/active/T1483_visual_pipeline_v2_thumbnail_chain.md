# T1483 — Visual Pipeline V2: Thumbnail Chain + Sidebar DnD Overhaul

## Objective
Replace the current circle-node visual pipeline with a **thumbnail-chain** design showing small rectangular scene previews, and migrate drag-and-drop reordering from the pipeline to the **sidebar scene list**.

---

## Revert Safety
The full V1 design is documented in [`docs/VISUAL_PIPELINE_V1_REFERENCE.md`](../../docs/VISUAL_PIPELINE_V1_REFERENCE.md).

---

## Part A: New Visual Pipeline (Thumbnail Chain)

### Design Specification

**Layout**:
- Position: Same as V1 — absolute bottom-center of the viewer builder, z-index 9000.
- Safe padding: 70px left (floor nav), 150px right (logo).
- Thumbnails arranged horizontally in a chain with `flex-wrap: wrap`.
- Max-width constraint (matching V1's 1200px or tighter) ensuring padding from logo/floor nav is always respected.
- Second row wraps with consistent vertical gap.

**Thumbnail Nodes**:
- Shape: Small **rectangles** (not circles). Approximately 48×32px (adjustable).
- Content: Scene thumbnail image (use `tinyFile` with fallback to `file`, same as V1).
- Border: **3px solid** using the scene's histogram-derived color (`ColorPalette.getGroupColor(scene.colorGroup)`).
- Border-radius: Small (4px) for a slightly rounded rectangle look.
- Active state: Brighter border glow + subtle scale-up.
- Hover: Tooltip with scene name + link info (same content as V1 tooltip).

**Sequence Arrows**:
- Between each thumbnail: A small **orange arrow** (→) indicating tour sequence direction.
- Use an inline SVG chevron or CSS triangle in `var(--orange-brand)`.
- Size: ~8-10px, vertically centered between thumbnails.

**Auto-Forward Indicator**:
- Same purple double-chevron badge as V1, positioned on the thumbnail corner.

**Duplicate Scenes**:
- Timeline items can reference the same `sceneId` multiple times (re-visited scenes).
- Each timeline entry gets its own thumbnail — duplicates are expected and intentional.
- This is the key difference from the sidebar scene list (where each scene appears exactly once).

**No Drag and Drop**:
- The pipeline is **read-only** for ordering. No D&D.
- Click-to-navigate remains (same `SetActiveTimelineStep` + `SetActiveScene` behavior).
- Right-click removal remains (or use a small × on hover).

**Responsive Scaling**:
- Compact mode for tablet/portrait/2k: Smaller thumbnails (~36×24px), tighter gaps.
- Portrait: `transform: scale(0.85)` on wrapper (same as V1).

### Files to Modify
- `src/components/VisualPipeline.res` — Replace `DropZone` with arrow separator, replace `PipelineNode` circle with thumbnail rectangle.
- `src/components/VisualPipelineLogic.res` — Rewrite Styles module for thumbnail chain CSS. Remove `calculateReorder` logic (no longer needed). 
- Remove the `setDragImage` binding usage (added in T1482 — can remain in DomBindings for sidebar use).

---

## Part B: Sidebar Scene List — Premium Drag & Drop

### Current State Analysis
The sidebar (`SceneList.res` + `SceneItem.res`) already has basic HTML5 DnD:
- `SceneItem` has `draggable=true` with `GripVertical` icon.
- `SceneList` tracks `draggedIndex` in state and dispatches `ReorderScenes(fromIndex, targetIndex)` on drop.
- **Problems**: No visual feedback during drag, no insertion indicator, no animation, no drop preview — same issues T1482 identified for the pipeline but even worse because the sidebar items are tall (64px) with complex content.

### Design Specification

**Drag Handle**:
- Keep the `GripVertical` icon (left edge of each scene item).
- On hover over the grip area: cursor changes to `grab`, slight color shift.
- On drag start: cursor to `grabbing`.

**Drag Ghost**:
- Use `setDragImage` to show a compact semi-transparent preview of the scene item (smaller than the original, ~60% size, with glass-blur background).

**Visual Feedback During Drag**:
- **Source item**: Dim to `opacity: 0.3`, `scale(0.97)`, subtle grayscale.
- **Other items**: Slight dim to `opacity: 0.8`.
- **Insertion indicator**: A glowing horizontal line (3px tall, full-width, `var(--orange-brand)`) appears between items at the drop position. Animated with a pulse glow.
- **Gap animation**: Items above/below the insertion point smoothly translate apart (8px each) using CSS `transform: translateY()` transitions to show where the dropped item will land.

**Drop Animation**:
- On drop: Items smoothly slide into their new positions over 200ms.
- Flash confirmation: Brief orange border flash on the moved item.

**Keyboard Accessibility**:
- Scene items already have `tabIndex=0` and keyboard navigation.
- Potential: Add `Alt+↑/↓` to reorder focused scene item.

### Files to Modify
- `src/components/SceneList.res` — Enhanced DnD state management (draggedIndex + dropTargetIndex for visual preview), insertion indicator rendering.
- `src/components/SceneList/SceneItem.res` — Drag ghost setup, drag states, keyboard reorder.
- `css/components/sidebar.css` or inline styles — Insertion line, gap animation, drag states.

---

## Implementation Order

### Phase 1: Document + Archive
- [x] Document V1 design in `docs/VISUAL_PIPELINE_V1_REFERENCE.md`
- [x] Archive T1482 → `completed/T1482_improve_visual_pipeline_drag_drop_DONE.md`

### Phase 2: Pipeline V2 — Thumbnail Chain
- [x] 2a. Design the thumbnail node component (replace PipelineNode circle with rectangular thumbnail)
- [x] 2b. Design the arrow separator (replace DropZone with static orange chevron)
- [x] 2c. Rewrite Styles module for thumbnail chain layout
- [x] 2d. Remove DnD handlers from pipeline (handleDragStart, handleDrop, DropZone DnD events)
- [x] 2e. Keep click-to-navigate + tooltip + auto-forward indicator
- [x] 2f. Responsive styling for compact viewports (tablet, portrait, 2k, fallback, stage-size-small)
- [x] 2g. Build verification — compiles cleanly
- [x] 2h. Update test file (removed calculateReorder tests, added Styles smoke test)

### Phase 3: Sidebar DnD Overhaul
- [ ] 3a. Add `dropTargetIndex` state to SceneList for insertion preview
- [ ] 3b. Implement insertion indicator (horizontal glowing line between scene items)
- [ ] 3c. Add gap animation (translateY on neighbors during drag)
- [ ] 3d. Custom drag ghost via `setDragImage`
- [ ] 3e. Drag source styling (dim, scale, grayscale)
- [ ] 3f. Drop animation (smooth settle + flash)
- [ ] 3g. Counter-based dragEnter/dragLeave to prevent flicker
- [ ] 3h. Build verification

### Phase 4: Polish
- [ ] 4a. Verify sidebar + pipeline visual consistency
- [ ] 4b. Test with 20+ scenes (wrapping, scroll, performance)
- [ ] 4c. Test portrait/tablet scaling

---

## Code Change Ledger
| File | Change | Revert Note |
|------|--------|-------------|
| `docs/VISUAL_PIPELINE_V1_REFERENCE.md` | Created V1 reference document | Delete file |
| `src/components/VisualPipeline.res` | Full rewrite: thumbnail nodes, arrow separators, no DnD | Restore from V1 reference or git |
| `src/components/VisualPipelineLogic.res` | Full rewrite: thumbnail chain CSS, removed Logic module | Restore from V1 reference or git |
| `tests/unit/VisualPipelineLogic_v.test.res` | Replaced calculateReorder tests with Styles smoke test | Restore from git |

---

## Rollback Check
- [ ] Confirmed CLEAN or REVERTED non-working changes

## Context Handoff
V1 is fully documented in `docs/VISUAL_PIPELINE_V1_REFERENCE.md`. Pipeline V2 replaces circles with small rectangular thumbnails chained by orange arrows, removes DnD from pipeline (read-only ordering), and moves DnD to the sidebar scene list with premium visual feedback.
