# Task 64 Completion Report: Migrate Constants to ReScript

## Objective
Migrate `src/constants.js` to `src/utils/Constants.res` for full type safety, compile-time checking, and better tree-shaking.

## Status
✅ **Completed**

## Changes Made

### 1. Created `src/utils/Constants.res`
- Implemented all constants from `src/constants.js` into a native ReScript module.
- Organized constants into logical modules (`Teaser`, `Scene`, `FFmpeg`).
- Followed camelCase naming convention for ReScript-native constants.
- Included `roomLabelPresets` as a dictionary to maintain compatibility with existing UI logic.

### 2. Updated All Usages
- Replaced `@module("../constants.js")` external bindings with direct references to the `Constants` module.
- Files updated:
    - `src/ReBindings.res` (Removed `module Constants`)
    - `src/systems/ExifParser.res`
    - `src/systems/DownloadSystem.res`
    - `src/systems/TeaserRecorder.res`
    - `src/components/Sidebar.res`
    - `src/systems/Navigation.res` (Fixed `ReBindings.Constants` references)
    - `src/components/ViewerLoader.res`
    - `src/components/ViewerSnapshot.res`
    - `src/utils/ProgressBar.res`
    - `src/utils/Logger.res`
    - `src/systems/BackendApi.res`
    - `src/systems/ProjectManager.res`
    - `src/systems/Resizer.res`
    - `src/systems/VideoEncoder.res`
    - `src/systems/ServerTeaser.res`
    - `src/systems/Exporter.res`

### 3. Cleanup
- Deleted `src/constants.js`.
- Verified no remaining references to `constants.js` in the codebase.
- Verified successful compilation with `npm run res:build`.

## Testing Results

### Compilation Tests
- ✅ `npm run res:build` completed with no errors.
- ✅ All `@module("./constants.js")` bindings removed.

### Functional Verification
- ✅ `Constants.backendUrl` resolves to correct value.
- ✅ Teaser canvas dimensions (`1920x1080`) are correctly referenced.
- ✅ Panning velocity and duration constants are correctly applied in `Navigation.res`.
- ✅ Room label presets are correctly loaded in `LabelMenu.res`.

## Impact
- **Type Safety**: Typos in constant names will now be caught at compile time.
- **Maintainability**: Single source of truth in `Constants.res`.
- **Performance**: Better tree-shaking as unused constants can be removed by the compiler.

## Rollback Plan
- Revert the commit `v4.2.26`.
- Restore `src/constants.js` and restore bindings in `ReBindings.res` and other files.
