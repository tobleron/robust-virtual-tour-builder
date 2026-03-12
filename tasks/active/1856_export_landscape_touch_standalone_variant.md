# 1856 Export Adaptive Touch Shell Finalization

## Objective

Finalize the exported adaptive tour shells so the normal `hd`, `2k`, and `4k` web outputs switch between classic desktop, portrait touch, and landscape touch UI at runtime based on the device/orientation. Keep a single 2K standalone HTML option, preserve the calibrated portrait and landscape touch UI work, and remove calibration-only export choices from the publish dialog.

## Scope

- Preserve the existing desktop/laptop classic UI for non-touch `hd`, `2k`, and `4k`.
- Make the normal web exports select `portrait-adaptive` or `landscape-touch` automatically on touch-primary devices.
- Keep a single 2K standalone HTML option in the export dialog.
- Remove the calibration-only landscape-touch standalone choices from the export dialog while leaving the calibrated touch-shell runtime intact.
- Use the 2K touch-shell orb sizing as the calibration baseline, then scale HD and 4K touch-shell orbs proportionally to stage size.
- Strengthen the touch-shell intro treatment so the panorama sits in grayscale plus blur while the 3 mode orbs are centered.
- Deprecate desktop map mode in favor of direct floor-button jumps and a standalone scene-number prompt on `n`.
- Expand the classic desktop glass panel to expose explicit navigation modes: manual (`m`), semi-auto (`s`), and auto (`a`).
- Show the centered 3-orb mode selector intro across all exported shells, with a resolution-scaled `Choose tour mode:` heading.
- Keep the scene-number prompt and looking-mode refinements isolated to classic desktop exports.
- Ensure desktop auto rows show explicit `auto 1x` / `auto 2x` wording.
- Surface the auto-tour return-home countdown inside the touch-shell mode selector instead of only in the classic glass panel.

## Constraints

- Do not regress the current desktop/laptop export UI behavior.
- Do not regress the current portrait export UI behavior except where shared adaptive-shell polish is required.
- Keep the landscape touch shell isolated enough that it can still be forced again later if needed for calibration/debugging.
- Prefer build verification first; keep unit-test churn minimal during UI calibration.
- Any shared desktop-control refactor must preserve the existing exported tour navigation semantics and only replace the deprecated map entry/shortcut path.

## Verification

- `npm run build`

## Notes

- The normal production export choices should now be: `HD`, `2K`, `4K`, and `Standalone HTML (2K default)`.
