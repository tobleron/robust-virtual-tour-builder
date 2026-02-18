# Task: 1472 - Export shortcuts under looking mode + screenshot shortcut

## Objective
Move export floor tag shortcuts under the Looking mode hint, limit visible rows to 3 plus `m` pagination, and add screenshot shortcut via `S`.

## Requirements
- Place floor tag shortcuts directly under Looking mode shortcut hints.
- Show max 3 tag rows at once; if more tags exist for floor, add 4th row with bold `m` and `more`.
- Add `S for screenshot` under `L to toggle` (only shortcut letter bold).
- Pressing `S` sets looking mode to OFF and downloads screenshot containing only panorama + logo + top center tag label + floor buttons (exclude white tag list and looking-mode hints).

## Verification
- `npm run build` succeeds.
- Export runtime behavior matches requirements.
