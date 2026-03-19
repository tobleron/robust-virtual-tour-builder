# Visual Pipeline — Design Reference

**Last Updated:** March 19, 2026  
**Version:** 5.3.6 (V4 - Graph Visualization with Edge Paths & Floor Lines)

> **Purpose**: This document captures the look, feel, and behavior of the Visual Pipeline, evolved to **V4 (Interactive Graph Visualization)** with edge paths, floor lines, and context-aware hover states.

---

## 1. Pipeline Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    VisualPipeline.res                       │
│  (Orchestration facade for graph visualization)             │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐  ┌────────────────┐  ┌─────────────────┐
│ VisualPipeline│  │ VisualPipeline │  │ VisualPipeline  │
│ Chrome        │  │ Graph          │  │ Navigation      │
│ (Container)   │  │ (Main canvas)  │  │ (Integration)   │
└───────────────┘  └────────────────┘  └─────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Edge Paths   │  │ Floor Lines  │  │ Node         │
│ (Connections)│  │ (Grouping)   │  │ (Scenes)     │
└──────────────┘  └──────────────┘  └──────────────┘
```

### Data Flow

```rescript
State (scenes, links, activeScene)
  → VisualPipelineData.res (transform to graph model)
  → VisualPipelineLogic.res (layout calculation)
  → VisualPipelineGraph.res (rendering orchestration)
    ├─ VisualPipelineEdges.res (edge rendering)
    ├─ VisualPipelineFloorLines.res (floor grouping)
    └─ VisualPipelineNode.res (scene nodes)
```

---

## 2. Visual Design (V4)

### Graph Layout

**Shape & Structure:**
- **Layout**: Force-directed graph with floor-based grouping
- **Nodes**: Square tiles with scene thumbnails
- **Edges**: Directed arrows showing navigation links
- **Floor Lines**: Visual separators between floor levels
- **Position**: Full-width container below viewer (replaces V3 bottom-center overlay)
- **Z-index**: 100 (below viewer controls, above background)

### Node Design

**States:**

| State | Visual Treatment |
|---|---|
| **Default** | Square tile with thumbnail, subtle border |
| **Active** | Yellow sync highlight, slight scale up (1.05x) |
| **Hover** | Border highlight, tooltip after 600ms |
| **Auto-Forward** | Emerald green border indicator |
| **Dead End** | Red tint, warning indicator |
| **Hub Scene** (2+ exits) | Blue border, hub icon |

**Node Sizes:**
- Standard: 80x80px (thumbnail 60x60px)
- Compact mode: 60x60px (thumbnail 40x40px)
- Large mode: 100x100px (thumbnail 80x80px)

### Edge Paths

**Visual Properties:**
- **Color**: Slate gray (`#64748b`) for standard links
- **Active Path**: Blue (`#3b82f6`) for current navigation path
- **Hovered Link**: Orange (`#f97316`) with glow effect
- **Width**: 2px standard, 4px on hover
- **Arrow Heads**: Directional indicators at target node

**Routing Styles:**
```rescript
type edgeRoutingStyle =
  | Straight          // Direct line (default)
  | Orthogonal        // 90° angles (PCB-style)
  | Curved            // Bezier curves
  | FloorAware        // Routes along floor lines
```

### Floor Lines

**Purpose:** Visual grouping of scenes by floor level

**Design:**
- **Color**: Light gray dashed line (`#e2e8f0`, `stroke-dasharray: 8,4`)
- **Label**: Floor name badge (e.g., "First Floor", "Second Floor")
- **Background**: Subtle tint to differentiate floor zones
- **Collapse/Expand**: Click to collapse floor group

### Tooltip (Scene Tag)

**Trigger:** Hover over node (600ms delay)

**Content:**
- Scene tag/name (truncated if > 30 chars)
- High-quality room preview thumbnail
- Link count indicator (e.g., "3 exits")
- Floor name
- Auto-forward status

**Style:**
```css
background: rgba(15, 23, 42, 0.95);
backdrop-filter: blur(4px);
border: 1px solid #f97316;
border-radius: 8px;
color: #f8fafc;
```

---

## 3. Interaction Model

### Click Interactions

| Click Target | Action |
|---|---|
| **Node (Left Click)** | Navigate to scene via `NavigationSupervisor` |
| **Node (Right Click)** | Open context menu (edit, delete, link) |
| **Edge (Left Click)** | Highlight link path, show link options |
| **Floor Line** | Collapse/expand floor group |
| **Empty Space** | Deselect, pan graph view |

### Hover Behavior

**Node Hover:**
1. Highlight node border
2. Dim non-related nodes (opacity 0.5)
3. Highlight connected edges
4. Show tooltip after 600ms
5. Slightly dim current viewport (focus effect)

**Edge Hover:**
1. Highlight edge path (orange, 4px width)
2. Show link direction arrow animation
3. Display link metadata (hotspot name, bidirectional status)

### Keyboard Shortcuts

| Key | Action |
|---|---|
| `F` | Fit graph to view |
| `+` / `-` | Zoom in/out |
| `1` / `2` / `3` | Switch layout mode (force/orthogonal/floor) |
| `H` | Toggle hub scenes only |
| `D` | Toggle dead-end scenes |

---

## 4. Component Architecture

### Component Tree

```
VisualPipeline.res (orchestration facade)
├─ VisualPipelineChrome.res (container, resize handling)
│  ├─ VisualPipelineActions.res (toolbar buttons)
│  └─ VisualPipelineStyles.res (theme variants)
│
├─ VisualPipelineGraph.res (main graph canvas)
│  ├─ VisualPipelineData.res (graph model transformation)
│  ├─ VisualPipelineLogic.res (layout calculation)
│  ├─ VisualPipelineEdges.res (edge rendering)
│  │  ├─ VisualPipelineEdgePaths.res (path geometry)
│  │  ├─ VisualPipelineEdgeSelection.res (selected edge)
│  │  ├─ VisualPipelineEdgeTypes.res (edge variants)
│  │  └─ VisualPipelineEdgeMaps.res (edge lookup maps)
│  │
│  ├─ VisualPipelineFloorLines.res (floor grouping)
│  │  └─ VisualPipelineTracks.res (floor track rendering)
│  │
│  └─ VisualPipelineNode.res (scene nodes)
│     ├─ VisualPipelineHover.res (hover state management)
│     ├─ VisualPipelineNavigation.res (navigation integration)
│     └─ PreviewArrow.res (directional preview indicator)
│
└─ VisualPipelineHooks.res (state subscriptions)
```

### Key Components

**VisualPipeline.res**
- Entry point and orchestration facade
- State subscription via `useAppContext()`
- Renders graph container

**VisualPipelineGraph.res**
- Main graph rendering canvas
- Manages pan/zoom state
- Coordinates edge and node rendering

**VisualPipelineNode.res**
- Individual scene node
- Handles click, hover, drag interactions
- Renders thumbnail and status indicators

**VisualPipelineEdges.res**
- Edge path rendering
- Manages edge selection and highlighting
- Calculates path geometry

**VisualPipelineFloorLines.res**
- Floor grouping visualization
- Collapse/expand functionality
- Floor label rendering

### State Integration

```rescript
// State selectors
let {state, dispatch} = useAppContext()

// Graph data derived from state
let graphData = VisualPipelineData.makeGraph(state.scenes, state.links)

// Layout calculated from graph
let layout = VisualPipelineLogic.calculateLayout(graphData, state.activeScene)

// Navigation integration
let handleNodeClick = nodeId => {
  NavigationSupervisor.requestNavigation(nodeId, dispatch)
}
```

---

## 5. Layout Algorithms

### Force-Directed Layout (Default)

```rescript
type forceLayout = {
  repulsion: float,      // Node repulsion force
  springLength: float,   // Edge spring length
  springStrength: float, // Edge spring strength
  damping: float,        // Movement damping
  floorGrouping: bool    // Enable floor-based grouping
}
```

**Parameters:**
- Repulsion: 500 (prevents node overlap)
- Spring Length: 150 (edge target length)
- Spring Strength: 0.1 (edge stiffness)
- Damping: 0.9 (movement smoothing)

### Orthogonal Layout (PCB-Style)

```rescript
type orthogonalLayout = {
  gridSize: int,         // Snap-to-grid size
  routing: routingStyle, // Edge routing style
  layering: bool         // Multi-layer routing
}
```

**Use Case:** Clean, architectural diagrams with 90° edge routing

### Floor-Aware Layout

```rescript
type floorLayout = {
  floorOrder: array<string>, // Explicit floor ordering
  floorSpacing: float,       // Space between floors
  intraFloorLayout: layout   // Layout within each floor
}
```

**Use Case:** Multi-story properties with clear floor separation

---

## 6. Performance Optimizations

### Rendering Optimizations

1. **Virtual Scrolling**: Only render visible nodes/edges
2. **Edge Simplification**: Simplify edge paths at low zoom levels
3. **Thumbnail Lazy Loading**: Load thumbnails on demand
4. **Canvas Caching**: Cache static graph elements
5. **RequestAnimationFrame**: Batch render updates

### State Optimizations

1. **Memoized Selectors**: Cache graph data calculations
2. **Debounced Layout**: Debounce layout recalculations (200ms)
3. **Edge Map Lookup**: Pre-compute edge lookup maps
4. **Node Indexing**: Index nodes by floor for fast filtering

### Performance Targets

| Metric | Target | Current |
|---|---|---|
| Graph Load (50 scenes) | < 500ms | ~300ms ✅ |
| Layout Calculation | < 200ms | ~150ms ✅ |
| Pan/Zoom FPS | 60 FPS | 60 FPS ✅ |
| Node Click → Navigate | < 100ms | ~50ms ✅ |

---

## 7. Canonical Traversal Integration

### Sequence Unification

Visual Pipeline integrates with `CanonicalTraversal.res` for consistent sequence generation:

```rescript
// Unified sequence across builder and exported tours
let sequence = CanonicalTraversal.generateSequence(scenes, links, startScene)

// Visual Pipeline renders sequence as ordered path
VisualPipelineGraph.renderSequence(sequence)
```

### Inline Hotspot Rendering

Hotspot rendering in Visual Pipeline matches exported tour behavior:

```rescript
// Hotspot style consistency
let hotspotStyle = TourTemplateHtmlSupportData.getHotspotStyle(link)

// Render in Visual Pipeline
VisualPipelineNode.renderHotspot(node, hotspotStyle)
```

---

## 8. Export Integration

### Tour Template Integration

Visual Pipeline layout influences exported tour navigation:

```rescript
// Export includes graph layout data
let exportData = Exporter.assembleExport(state, visualPipelineLayout)

// Tour template uses layout for initial view
TourTemplateHtml.renderPipeline(exportData.pipelineLayout)
```

### Floor Navigation

Exported tours preserve floor grouping:

```rescript
// Floor navigation in exported tour
TourScriptNavigation.enableFloorNavigation(floorGroups)
```

---

## 9. Related Documents

- **[Navigation Architecture](../architecture/overview.md#navigation-architecture-v536)** - NavigationSupervisor pattern
- **[Scene Transitions](../architecture/overview.md#dual-viewer-pool)** - Dual-viewer crossfade system
- **[Export System](../architecture/overview.md#media-processing-pipeline)** - Export packaging
- **[Testing Strategy](./testing_strategy.md)** - Visual regression testing

---

## 10. Appendix: Component File Reference

### Core Components
- `src/components/VisualPipeline.res` - Orchestration facade
- `src/components/VisualPipelineGraph.res` - Main graph canvas
- `src/components/VisualPipelineNode.res` - Scene nodes
- `src/components/VisualPipelineEdges.res` - Edge rendering

### Edge Components
- `src/components/VisualPipelineEdgePaths.res` - Path geometry
- `src/components/VisualPipelineEdgeSelection.res` - Selected edge
- `src/components/VisualPipelineEdgeTypes.res` - Edge variants
- `src/components/VisualPipelineEdgeMaps.res` - Edge lookup maps

### Floor Components
- `src/components/VisualPipelineFloorLines.res` - Floor grouping
- `src/components/VisualPipelineTracks.res` - Floor track rendering

### Support Components
- `src/components/VisualPipelineData.res` - Graph model transformation
- `src/components/VisualPipelineLogic.res` - Layout calculation
- `src/components/VisualPipelineHooks.res` - State subscriptions
- `src/components/VisualPipelineHover.res` - Hover state management
- `src/components/VisualPipelineNavigation.res` - Navigation integration
- `src/components/VisualPipelineActions.res` - Toolbar actions
- `src/components/VisualPipelineStyles.res` - Theme variants
- `src/components/VisualPipelineChrome.res` - Container

### Related Components
- `src/components/PreviewArrow.res` - Directional preview indicator
- `src/components/Tooltip.res` - Tooltip rendering
- `src/components/SceneList.res` - Scene list (alternative navigation)

---

**Document History:**
- March 19, 2026: Updated for V4 (Graph Visualization) with edge paths, floor lines, and interactive graph layout
