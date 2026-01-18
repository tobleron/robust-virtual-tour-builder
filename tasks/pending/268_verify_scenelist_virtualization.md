# Task: Verify and Stabilize SceneList Virtualization

## Context
Users reported issues with the `SceneList` component in the Sidebar:
1.  **Missing Images:** "Out of 38, I see only 20 images."
2.  **Scrolling Issues:** Scrolling resulted in blank spaces or fewer images being rendered.
3.  **UI Glitch:** Percentage display showed decimals (Fixed).

## Attempted Fixes
The following changes have been applied to `src/components/SceneList.res`:
1.  **Buffer Increase:** Increased the render buffer from `3` to `10` items to pre-load more content off-screen.
2.  **Scroll Container Fallback:** Added a `querySelector(".sidebar-content")` fallback in case `ReBindings.Dom.closest` fails to locate the scrollable parent.
3.  **Minimum Visibility:** Enforced a `Math.max(10.0, ...)` for `visibleCount` to ensure at least 10 items are calculated as "visible" even if `clientHieght` is reported as 0 or small.

## Current Status
The UI percentage issue is resolved. The scrolling stability *should* be improved by the latest fixes, but the user report ("I see less images now") suggests potential lingering edge cases with the virtualization logic or DOM height calculations.

## Next Steps
1.  **Verify Event Listeners:** Confirm that the `scroll` event listener is attaching correctly to `.sidebar-content` in all lifecycle scenarios.
2.  **Validate Dimensions:** Check if `itemHeight = 112.0` strictly matches the actual rendered height of `SceneItem` (including margins). If the CSS changes, this constant breaks the math.
3.  **Debug State:** If issues persist, add temporary logging to `SceneList.res` to inspect `scrollTop`, `viewportHeight`, `startIndex`, and `endIndex` during scroll events.
4.  **Consider Libraries:** If custom virtualization remains brittle, evaluate switching to `react-window` or `react-virtualized` (via bindings).
