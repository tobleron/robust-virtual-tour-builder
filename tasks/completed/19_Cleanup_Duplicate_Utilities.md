# Task: Cleanup Legacy Duplicate Utilities

## Objective
Remove redundant JavaScript utility files that have been fully replaced by ReScript modules, and ensure all remaining JS imports use the compiled `.bs.js` versions.

## Context
Modules like `TourLogic`, `PathInterpolation`, and `ColorPalette` now exist in both `.js` and `.res`. Keeping the `.js` versions causes confusion and potential bugs if logic diverges.

## Implementation Steps

1. **Audit Imports**:
   - Search for all remaining imports of `TourLogic.js`, `PathInterpolation.js`, and `ColorPalette.js`.
   - Update them to point to the `.bs.js` versions in their respective folders.

2. **Delete Files**:
   - Delete `src/utils/TourLogic.js`.
   - Delete `src/utils/PathInterpolation.js`.
   - Delete `src/utils/ColorPalette.js`.

3. **Verify Build**:
   - Run `npm run res:build`.
   - Ensure the application launches and basic math/coloring works (e.g., node colors in Visual Pipeline).

## Testing Checklist
- [x] Nodes in Visual Pipeline are correctly colored.
- [x] Scene filename generation (TourLogic) works when uploading.
- [x] No "File not found" errors in browser console.

## Definition of Done
- No `.js` versions of migrated utilities remain in the project.
- All code correctly imports from compiled ReScript output.
