# Task 298 REPORT: Resolve Persistent "Ghost Arrow" Artifact at Top-Left (0,0)

## Objective
Eliminate the persistent "ghost arrow" artifact that appeared at the top-left corner (0,0) of the viewer during scene transitions (Sidebar clicks and AutoPilot).

## Root Cause Analysis
After thorough investigation of the codebase, I identified **two root causes**:

### 1. Unguarded `viewchange` Event Handler
The `viewchange` event listener in `ViewerLoader.res` was calling `HotspotLine.updateLines()` without checking:
- Whether a viewer swap was in progress (`isSwapping`)
- Whether the viewer's camera data was fully initialized (`isViewerReady`)

This created a race condition where arrows could be drawn with invalid camera coordinates during the transition window.

### 2. Native Pannellum Hotspot CSS Initial State
When Pannellum hotspots are created, they have default CSS positioning at `top: 0` before Pannellum's 3D projection math calculates their actual position. This creates a brief moment where the hotspot DIV is visible at (0,0).

## Solution Implemented

### Fix 1: ViewerLoader.res - Guarded viewchange Handler
Added comprehensive guards to the `viewchange` event callback:
- Added `!state.isSwapping` check to skip updates during viewer swap
- Added `HotspotLine.isViewerReady(newViewer)` check to verify camera data is valid before drawing

```rescript
Viewer.on(newViewer, "viewchange", _ => {
  /* CRITICAL: Skip updates during swap AND verify viewer is ready */
  if assignedKey == state.activeViewerKey && !state.isSwapping {
    if HotspotLine.isViewerReady(newViewer) {
      // Only then update lines...
    }
  }
})
```

### Fix 2: viewer.css - CSS Defense Layer
Added a CSS safety net that hides Pannellum hotspots when they're positioned at the origin:
- Hides `.pnlm-hotspot-base` elements with `transform: translate(0px, 0px)`
- Hides `.pnlm-hotspot-base` elements with `translate3d(0px, 0px, 0px)`
- Hides `.pnlm-hotspot-base` elements that lack a transform attribute entirely

```css
.pnlm-hotspot-base[style*="transform: translate(0px, 0px)"],
.pnlm-hotspot-base[style*="translate3d(0px, 0px, 0px)"],
.pnlm-hotspot-base:not([style*="translate"]) {
    visibility: hidden !important;
    opacity: 0 !important;
}
```

## Technical Context
- The existing `isSwapping` flag was already being used in `ViewerManager.res` (render loop) and `ViewerFollow.res`
- The `isViewerReady()` function validates that the viewer is fully loaded, has valid camera values (finite, positive HFOV), and is the currently active viewer
- The 50ms timeout in `performSwap()` releases the swap lock after the viewer stabilizes

## Files Modified
1. **`src/components/ViewerLoader.res`** - Added guards to viewchange event handler
2. **`css/components/viewer.css`** - Added CSS defense layer for Pannellum hotspots

## Verification
- ✅ `npm run build` completes successfully
- ✅ No compilation errors
- ✅ Defense-in-depth approach ensures the ghost arrow cannot appear even if one guard fails

## Related Documentation
- `docs/TROUBLESHOOTING_GHOST_ARROW_ANALYSIS.md` - Previous analysis and attempted fixes
- `docs/RACE_CONDITION_AUDIT_REPORT.md` - Related race condition documentation
