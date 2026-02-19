# Visual Pipeline V1 — Design Reference (Revert Document)

> **Purpose**: This document captures the exact look, feel, and behavior of the Visual Pipeline V1  
> so it can be restored if the V2 thumbnail-chain migration is unsuccessful.  
> **Snapshot Date**: 2026-02-19  
> **Files**: `src/components/VisualPipeline.res`, `src/components/VisualPipelineLogic.res`

---

## 1. Visual Design

### Shape & Layout
- **Shape**: A horizontal chain of **circles** (pipeline nodes) connected by **pipe segments** (drop zones).
- **Position**: Absolute-positioned at the **bottom center** of the viewer builder window.
- **Z-index**: 9000 (above viewer, below modals).
- **Max width**: 1200px. If the chain exceeds this, it **wraps** to a second row with `flex-wrap: wrap` and `row-gap: 18px`.
- **Safe padding**: `padding-left: 70px` (clears floor nav buttons) and `padding-right: 150px` (clears logo).
- **Bottom margin**: `--vp-bottom-margin: 24px` (compact: 12px).
- **Visibility**: Hidden when `timeline` array is empty. Shown as `display: flex` otherwise.

### Node Circles
- **Size**: `--vp-node-base: 18px` (compact: 14px) + 4px = 22px total.
- **Base color**: `var(--primary-ui-blue)` solid fill.
- **Orange stripe**: A horizontal gradient stripe (Golden Minor Ratio 38.2%–61.8%) of `var(--orange-brand)` passes through the center of each node, aligning with the pipe connectors.
- **Active state**: An inner marker circle (`--vp-marker-size: 10px + 4px`) of solid orange scales in via `transform: scale(1)` with a springy easing `cubic-bezier(0.175, 0.885, 0.32, 1.275)`.
- **Start/End truncation**: First node shows the stripe only on the right half, last node only on the left half. Single node has no stripe.
- **Hover**: `box-shadow: 0 0 0 2px rgba(255, 255, 255, 0.3)`.
- **Active press**: `transform: scale(0.95)`.
- **Dragging state**: `opacity: 0.35`, `scale(0.85)`, `filter: grayscale(40%)`.
- **During drag (non-dragged nodes)**: Dimmed to `opacity: 0.7`.

### Pipe Connectors (Drop Zones)
- **Size**: 30px wide × 32px tall by default.
- **Pipe visual**: A `::before` pseudo-element shows a horizontal gradient bar matching the node stripe — blue on outside, orange in middle (Golden Minor Ratio).
- **Drop indicator**: A `::after` pseudo-element shows a 3px × 28px white glowing vertical line with `vp-insertion-pulse` animation (pulsing box-shadow 0→14px).
- **Drag-over state**: Expands to 40px, pipe fades to 30% opacity, insertion line appears.
- **Endpoint zones**: Invisible when not dragging (`display: none`). Shown as 24px during drag, 40px on drag-over.

### Tooltip
- **Trigger**: Hover over any node.
- **Content**: Link ID label, scene thumbnail (tiny file or main file), and scene name.
- **Style**: Dark glass panel (`rgba(15, 23, 42, 0.95)`, `backdrop-filter: blur(4px)`) with 8px border-radius.
- **Size**: 160px wide, positioned above the node.
- **Animation**: Slides up from 10px below with opacity 0→1 over 0.2s.

### Auto-Forward Indicator
- **When**: Shown if the scene's hotspot for this link has `isAutoForward: Some(true)`.
- **Visual**: A 20px purple circle (`#4B0082`) centered on the node with a white double-chevron icon (`ChevronsRight`, 12px, strokeWidth 3).

### Responsive Scaling
| Viewport Class | `--vp-node-base` | `--vp-pipe-height` | `--vp-marker-size` | `--vp-bottom-margin` |
|---|---|---|---|---|
| Default | 18px | 12px | 10px | 24px |
| `viewer-state-tablet` / `portrait` / `2k` / `force-fallback` / `stage-size-small` | 14px | 10px | 8px | 12px |

Portrait mode additionally applies `transform: scale(0.85)` with `transform-origin: bottom center` and tighter padding.

### Color System
- Node border/fill color = `ColorPalette.getGroupColor(scene.colorGroup)` — derived from the histogram calculation during upload.
- Pipeline uses CSS custom property `--node-color` per node and `--pipe-color` per drop zone for per-item tinting.

---

## 2. Interaction Model

### Click to Navigate
- Clicking a node activates the corresponding timeline step via `SetActiveTimelineStep(Some(itemId))`.
- Then resolves the `sceneId` from the timeline item and calls `SetActiveScene(sceneIdx, yaw, pitch, None)` to navigate the viewer — using the hotspot's yaw/pitch if available.

### Drag and Drop (Scene Reordering)
- **Mechanism**: HTML5 Drag and Drop API.
- **Drag start**: Sets `effectAllowed: "move"`, stores item ID in `dataTransfer`. Uses a transparent 1×1 canvas as drag image (browser ghost suppressed).
- **Drop zones**: `DropZone` components between each node and at endpoints. Use counter-based enter/leave tracking to prevent flickering.
- **Reorder logic**: `Logic.calculateReorder(timeline, sourceId, dropIndex)` computes `(sourceIndex, finalIndex)` adjusting for the shift when dropping after the source. Dispatches `ReorderTimeline(sourceIndex, finalIndex)`.
- **Context menu**: Right-click on a node removes the step from the timeline via `RemoveFromTimeline(itemId)`.

### Keyboard
- `Enter` or `Space` on a focused node activates it (same as click).
- Nodes have `tabIndex=0` and `role="button"`.

---

## 3. Data Model

### Timeline Items
```
type timelineItem = {
  id: string,
  linkId: string,
  sceneId: string,
  targetScene: string,
  transition: string,
  duration: int,
}
```

- The `timeline` array lives in `state.timeline`.
- Scenes can appear **multiple times** in the timeline (re-visited scenes).
- Each timeline item maps to a specific hotspot link (`linkId`) on a specific scene (`sceneId`).
- The visual pipeline renders one node per timeline item.

### Active Step Tracking
- `state.activeTimelineStepId: option<string>` tracks which pipeline node is currently active/highlighted.
- When no explicit step is active, the component falls back to highlighting the first timeline item matching the current active scene.

### Reducer Actions
- `AddToTimeline(json)` — Appends a parsed timeline item.
- `SetTimeline(timeline)` — Replaces the entire timeline array.
- `SetActiveTimelineStep(idOpt)` — Highlights a specific step.
- `RemoveFromTimeline(id)` — Removes a step by ID.
- `ReorderTimeline(fromIdx, toIdx)` — Moves item from one index to another.
- `UpdateTimelineStep(id, dataJson)` — Updates transition/duration of a step.

---

## 4. Component Architecture

### File Structure
```
src/components/VisualPipeline.res      — Main React component (DropZone, PipelineNode, make)
src/components/VisualPipelineLogic.res  — Logic module (calculateReorder) + Styles module (CSS-in-JS string)
```

### Sub-Components
| Component | Purpose |
|---|---|
| `DropZone` | Invisible gap between nodes; handles drag-over/drop events and shows insertion indicator |
| `PipelineNode` | Individual circle node; handles click, drag start/end, context menu; shows tooltip + auto-forward badge |

### State Selectors
- `AppContext.usePipelineSlice()` — Returns `{ scenes, timeline, activeIndex, activeTimelineStepId }`.
- `AppContext.useAppDispatch()` — Dispatch function.

### Performance
- `PerfUtils.useRenderBudget("VisualPipeline")` monitors render time.
- Styles are injected once via a `<style>` tag with `id="visual-pipeline-styles"`.
- Thumbnail URLs use `tinyFile` (smaller preview) with fallback to main `file`.

---

## 5. CSS-in-JS Injection

Styles are defined as a multiline string in `VisualPipelineLogic.Styles.styles` and injected into `<head>` as a `<style id="visual-pipeline-styles">` element. This is done on every render via `injectStyles()` but is idempotent (reuses existing element).

### Keyframe Animations
- `vp-insertion-pulse` — Pulsing white glow on the insertion line indicator.
- `vp-lift` — Scale-up with shadow (defined but currently unused — available for future enhancement).

---

## 6. Known Limitations (V1)

1. **No touch support** — HTML5 D&D has no native mobile/touch support.
2. **Simulation ignores timeline order** — The autopilot simulation follows hotspot graph traversal, not the visual pipeline's timeline order.
3. **No smooth reorder animation** — Nodes re-render instantly after drop with no transition.
4. **CSS-in-JS string** — Styles are embedded in ReScript strings, making attribute selectors with quotes tricky (must avoid `"` inside the string).
