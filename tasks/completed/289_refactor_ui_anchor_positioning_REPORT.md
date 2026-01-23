# Task 289: Refactor UI elements to use Anchor-Based Positioning - REPORT

## Objective
Refactor existing UI elements that rely on manual positioning or browser defaults to use a robust, anchor-based positioning system to ensure a premium, consistent, and stable user experience across all browsers and screen sizes.

## Technical Realization
1. **Refactored Room Label Menu**: 
   - Converted the legacy manual DOM creation logic in `LabelMenu.res` into a fully-featured React component.
   - Integrated it into `ViewerUI.res` using the `Shadcn.DropdownMenu` system, which provides native anchor-based positioning and boundary awareness.
2. **Premium Tooltips**:
   - Implemented a reusable `Tooltip.res` component powered by Radix UI (via Shadcn).
   - Replaced all browser-default `title` attributes on primary viewer buttons and floor navigation elements with these premium tooltips.
3. **Hotspot Action Menus**:
   - Created `HotspotActionMenu.res` to decouple hotspot actions (Delete, Toggle Auto-Forward) from the 3D-plane labels.
   - Implemented a virtual-anchor system in `ViewerUI.res` that opens a `Shadcn.Popover` exactly at the coordinate of the hotspot's "more" button.
4. **Global Boundary Awareness**:
   - Leveraged Radix UI's "clamping" and "flipping" logic to ensure that all menus and tooltips stay within the viewport, automatically adjusting their position if they would otherwise be cut off.

## Outcome
The UI is now significantly more robust and "premium". Elements no longer jitter or get cut off at screen edges, and the code follows modern React patterns instead of manual DOM manipulation.
