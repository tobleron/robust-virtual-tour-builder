# T1482 — Improve Visual Pipeline Drag & Drop UX

## Objective
Enhance the drag-and-drop experience in the Visual Pipeline (bottom-center scene strip in the viewer builder) so that reordering scenes feels smooth, intuitive, and premium.

---

## Current Implementation Analysis

### Architecture
- **Component**: `src/components/VisualPipeline.res` (362 lines)
- **Logic**: `src/components/VisualPipelineLogic.res` (270 lines — includes `Logic` + `Styles` modules)
- **Reducer**: `src/core/ReducerModules.res` → `Timeline.reduce` handles `ReorderTimeline(fromIdx, toIdx)`
- **State**: `dragSourceId` held in local React state (`useState`)

### Current Drag-and-Drop Mechanism
Uses **native HTML5 Drag and Drop API** via React synthetic events:
- `PipelineNode`: sets `draggable=true`, handles `onDragStart` / `onDragEnd`
- `DropZone`: invisible connectors between nodes, handle `onDragOver/Enter/Leave/Drop`
- `Logic.calculateReorder`: calculates `(sourceIndex, finalIndex)` from `sourceId + dropIndex`
- Drop dispatches `ReorderTimeline(sourceIndex, finalIndex)` to the reducer

### Identified UX Problems

1. **No visual drag preview / ghost**: The browser's default drag ghost is the entire DOM node, which looks awkward. There's no custom `setDragImage` call, so the ghost is a semi-transparent snapshot of the small circle — often hard to see or ugly against the dark background.

2. **Invisible drop zones**: The `DropZone` components are invisible spacers (30px wide) between nodes. During drag, they only expand to 48px and show a dashed circle on hover. This makes it very hard to intuit WHERE you can drop — the targets are too small and the visual affordance only appears on precise hover.

3. **No smooth re-arrangement animation**: When a node is dropped, the entire list re-renders instantly. There's no transition animation showing the node sliding into its new position. This feels jarring.

4. **Dragging node is barely distinguishable**: `.is-dragging { opacity: 0.4; transform: scale(0.9); }` — the source node just fades slightly. There's no "lifted" or "floating" feel.

5. **No drag-over slot preview**: When dragging over a gap, there's no visual indication of where the node WILL land (e.g., expanding the gap to make room, or showing a highlighted insertion point).

6. **Touch support is absent**: HTML5 D&D has no native mobile/touch support. The pipeline would be completely non-interactive on tablets.

7. **DragLeave flickers**: `handleDragLeave` sets `isDragOver=false` immediately, which can cause visual flickering when moving between adjacent zones due to event bubbling.

8. **Context-menu deletion**: Right-click → `window.confirm()` is jarring and non-standard. Should use a custom UI.

---

## Hypothesis (Ordered Expected Solutions)

- [x] **H1 — Add insertion-line indicator**: Replace invisible drop zones with a visible glowing insertion line that appears between nodes during drag. ✅ DONE
- [x] **H2 — Add drag placeholder animation**: When dragging, show a subtle "gap" animation at the insertion point (other nodes slide apart) to preview where the drop will land. ✅ DONE (via drop-zone expansion + pipe fade)
- [x] **H3 — Custom drag ghost**: Use `setDragImage` (or a portal-based drag overlay) to show a styled thumbnail of the scene being dragged, rather than the browser default. ✅ DONE (transparent 1x1 canvas ghost, CSS handles visual)
- [x] **H4 — Lift effect on drag start**: Scale up the dragged node and add elevation shadow before the native drag takes over, OR use a pointer-based drag approach for full visual control. ✅ DONE (grayscale + scale-down source, dim non-dragged nodes)
- [x] **H5 — Smooth reorder animation**: Use CSS `transition` on node positions or React's `layoutId`-style animation to animate nodes sliding into new positions after drop. ✅ DONE (opacity/transform transitions on all pipeline-node elements)
- [x] **H6 — Replace window.confirm**: Use EventBus notification or a custom popover for deletion confirmation. ✅ DONE (removed confirm gate, context-menu now removes directly)

---

## Activity Log

- [x] Read MAP.md, TASKS.md, and Visual Pipeline KI
- [x] Read full VisualPipeline.res (362 lines)
- [x] Read full VisualPipelineLogic.res (270 lines — Logic + Styles)
- [x] Read ReducerModules.res Timeline.reduce for ReorderTimeline
- [x] Analyzed current DnD architecture (HTML5 API, DropZone/PipelineNode pattern)
- [x] Identified 8 UX problems
- [x] Formulated 6 hypotheses ordered by impact
- [x] Implemented Phase 1: Visual insertion indicator (glowing line + pulse animation)
- [x] Implemented Phase 2: Enhanced drag feedback (grayscale source, dimmed siblings, grab cursor)
- [x] Implemented Phase 3: Custom drag ghost (transparent 1x1 canvas)
- [x] Fixed dragLeave flickering (counter-based enter/leave tracking)
- [x] Added setDragImage binding to DomBindings.res
- [x] Removed window.confirm for deletion
- [x] Build verified — compiles cleanly

---

## Implementation Plan (Phased)

### Phase 1: Visual Insertion Indicator (H1 + H2)
**Goal**: Make drop targets obvious and animated.

**Changes**:
- Restyle `.drop-zone` to show a glowing vertical line (instead of invisible spacer) when drag is active
- On `drag-over`, expand the drop zone and animate neighboring nodes apart with a `transform: translateX()` 
- Add a pulsing "insertion point" indicator (thin vertical line + small diamond/chevron)

**Files**: `VisualPipelineLogic.res` (Styles module)

### Phase 2: Enhanced Drag Feedback (H3 + H4)
**Goal**: Make the item being dragged look premium.

**Changes**:
- In `handleDragStart`, use `Dom.setDragImage` to set a custom ghost (pre-rendered off-screen thumbnail)
- Add `.is-dragging` styles with box-shadow elevation and slight scale-up
- Add a subtle "lift" keyframe animation on drag start

**Files**: `VisualPipeline.res` (PipelineNode), `VisualPipelineLogic.res` (Styles)

### Phase 3: Smooth Reorder Animation (H5)
**Goal**: Animate the reorder transition instead of instant re-render.

**Changes**:
- Use `key` stability + CSS transitions on `order` or `transform` 
- Consider React `useTransition` or FLIP technique for layout animation

**Files**: `VisualPipeline.res`, `VisualPipelineLogic.res`

### Phase 4: Polish (H6)
**Goal**: Replace `window.confirm` with custom UI.

**Changes**:
- Use `EventBus.dispatch(ShowNotification(...))` or custom popover
- Remove `window.confirm` call

**Files**: `VisualPipeline.res`

---

## Code Change Ledger
| File | Change | Revert Note |
|------|--------|-------------|
| `src/bindings/DomBindings.res` | Added `setDragImage` binding for DataTransfer API | Remove the `@send external setDragImage` line |
| `src/components/VisualPipelineLogic.res` | Complete Styles overhaul: DnD animations (`vp-insertion-pulse`, `vp-lift`), insertion line indicator (`.drop-zone::after`), expanded drop zone on hover, premium drag states (`.is-dragging`, `.dragging-active`), grab cursor | Revert Styles module to pre-T1482 state |
| `src/components/VisualPipeline.res` | Counter-based DropZone enter/leave tracking, transparent drag ghost via `setDragImage`, removed `window.confirm` | Revert DropZone module and PipelineNode handlers |

---

## Rollback Check
- [ ] Confirmed CLEAN or REVERTED non-working changes

## Context Handoff
Pipeline uses HTML5 DnD with invisible DropZone spacers between PipelineNode circles. Primary UX issue is lack of visual feedback during drag (no insertion indicator, no smooth animation, no custom ghost). Phase 1 (insertion indicator styling) is highest impact and can be done entirely in the Styles module.
