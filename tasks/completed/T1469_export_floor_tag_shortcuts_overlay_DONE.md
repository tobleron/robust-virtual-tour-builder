# Task: T1469 - Export floor tag shortcuts overlay

## Objective
Add an exported-tour-only feature that shows floor-scoped scene tags in the top-right viewer area with numeric keyboard shortcuts.

## Requirements
- For the currently selected floor in export, list scene tags for scenes on that floor.
- Render up to 6 rows at a time in small white text on the top-right (no box), formatted as bold index + tag text.
- Exclude the current scene tag from the top-right list.
- Keyboard number keys (1-6) should navigate to the listed scene.
- On navigation by keyboard shortcut, animate/promote that selected tag into the existing top-center blue label container.
- If more than 6 tags exist, show a 7th row as bold `M` + `More` indicator and paginate/rotate remaining tags when `M` is clicked or key `m`/`M` is pressed.
- Maintain existing floor button spacing/behavior.

## Verification
- Build succeeds (`npm run build`).
- Exported runtime shows floor-specific tag list and supports keyboard shortcuts and M pagination.

