# 1466 - Export floor buttons and scenes from explicit floor assignments only

## Objective
Implement an export-only floor filtering behavior so exported tours include only scenes with an explicitly set floor and only render floor buttons for floors used by exported scenes.

## Scope
- Export pipeline (`src/systems/Exporter.res`): filter exported scenes to those with non-empty `scene.floor`.
- Export runtime template (`src/systems/TourTemplates.res`): render floor nav buttons from floors present in exported `scenesData` only.
- Preserve existing floor button spacing and styling.

## Requirements
- If at least one exported scene has floor `ground`, `G` floor button must be present.
- Any floor button appears only if at least one exported scene uses that floor.
- Scenes with blank/unset floor must not appear in exported tours.
- Existing floor button spacing and visual behavior remain unchanged.
- Export fails with a clear message when no scenes have a floor set.

## Verification
- Build passes: `npm run build`.
- Manual sanity: export a project with mixed floor-set and unset scenes; verify only floor-set scenes are navigable and floor nav shows only used floors.

## Notes
This change is surgical and export-only. Builder behavior remains unchanged.
