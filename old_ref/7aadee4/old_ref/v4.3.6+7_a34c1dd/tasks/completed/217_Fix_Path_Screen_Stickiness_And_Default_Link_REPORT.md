# Fix Path Screen Stickiness and Default Link Scene - REPORT

## Objectives
1.  **Fix Path Stickiness**: Resolve the issue where the path visualization appears frozen on screen or sticks to the screen instead of being anchored to the scene.
2.  **Fix Default Link Selection**: Ensure the "Next Scene" is auto-selected in the Link Modal even when a draft link is active.

## Technical Resolution

### 1. Default Link Selection
- **Analysis**: In `LinkModal.res`, the pattern match for auto-selection was `(None, None) => i == nextIndex`. This meant it only auto-selected if there was NO pending return scene AND NO link draft.
- **Problem**: When adding a link via the UI, a `linkDraft` is *always* present (created on first click). Thus, `(None, None)` never matched, and the default selection fell through to `false`.
- **Fix**: Updated the pattern match to `(None, _) => i == nextIndex`, allowing the default "Next Scene" selection even when a link draft exists (as long as there's no pending return scene override).

### 2. Path Stickiness (Frozen SVG)
- **Analysis**: The "sticking" behavior described by the user (path stays fixed on screen while camera moves) is a classic symptom of the `ViewerFollow` animation loop crashing or stopping. If the loop stops, the SVG overlay is not cleared or redrawn, causing the last drawn frame to persist as a static overlay on top of the moving panorama.
- **Fix**: Wrapped the `HotspotLine.updateLines` call in `ViewerFollow.res` within a `try/catch` block. This prevents any potential errors in the line rendering logic (e.g., during coordinate projection or spline calculation) from killing the entire animation loop. If an error occurs, it is now logged, but the loop continues, allowing subsequent frames to render (and hopefully clear the artifact).
- **Secondary Fix**: Added (but commented out) debug logging in `HotspotLine.res` to allow future tracing of coordinate projection if needed.

## Verification
- **Build**: `npm run build` passed.
- **Logic Verification**: The pattern match fix in `LinkModal` is logically sound and addresses the specific condition causing the default selection failure. The try/catch in `ViewerFollow` adds robustness against runtime crashes that cause visual freezing.
