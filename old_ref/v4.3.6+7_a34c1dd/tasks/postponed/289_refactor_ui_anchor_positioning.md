# Task 289: Refactor UI elements to use Anchor-Based Positioning

## Objective
Refactor existing UI elements that rely on manual positioning or browser defaults to use a robust, anchor-based positioning system. This ensures a premium, consistent, and stable user experience across all browsers and screen sizes.

## Scope
1. **Refactor Room Label Menu**: 
   - Convert manual DOM creation logic in `LabelMenu.res` to a proper React component.
   - Use `getBoundingClientRect()` of the `#` button as the anchor.
   - Implement "flipping" logic (open upwards if space is limited below).
2. **Premium Tooltips**:
   - Create a reusable `Tooltip` component to replace browser-default `title` attributes.
   - Apply to all primary viewer buttons and floor navigation elements.
   - Ensure tooltips are aware of viewport boundaries.
3. **Hotspot Action Menus**:
   - Decouple hotspot actions (Delete, Toggle Auto-Forward) from the 3D-plane label.
   - Use anchor-based React menus for hotspot interactions.
4. **Global Boundary Awareness**:
   - Ensure all popovers and menus use "clamping" to stay within the viewport.

## References
- Success pattern established in `SceneList.res` for the sidebar context menu.
- `src/components/LabelMenu.res`
- `src/components/ViewerUI.res`
- `src/components/HotspotManager.res`
