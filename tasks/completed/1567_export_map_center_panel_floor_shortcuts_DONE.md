# 1567 Export Map Center Panel Floor Shortcuts

## Objective
Implement export runtime map mode (`m` shortcut + map row click) so the existing glass panel transitions into centered map view and renders floor-to-tag rows in strict shortcut text format with one best tag per floor (most links).

## Scope
- `src/systems/TourTemplates/TourScriptUI.res`
- `src/systems/TourTemplates/TourScriptInput.res`
- `src/systems/TourTemplates/TourStyles.res`

## Requirements
1. Trigger map mode via `m/M` and map shortcut row click.
2. Animate glass panel to center with dedicated map mode style.
3. Render rows as plain shortcut text format (no circular buttons):
   - `r Roof: tag_name`
   - `2 Second floor: tag_name`
   - `1 First floor: tag_name`
   - `g Ground floor: tag_name`
   - `b Basement level -1: tag_name`
   - `z Basement level -2: tag_name`
4. One tag per floor, chosen by most links in that floor.
5. Keep ordering top-to-bottom from roof down to basement.
6. Keep shortcuts panel behavior intact outside map mode.

## Verification
- Run `npm run build` successfully.
