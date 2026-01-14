# Task: Migrate Supporting System Modules

## Objective
Migrate the remaining smaller JavaScript system and utility modules to ReScript to reach 95%+ code coverage.

## Context
These are utility modules that handle specific browser APIs like `MediaRecorder`, `Audio`, `IndexedDB`, etc.

## Implementation Steps

1. **Migrate Utility Modules**:
   - `InputSystem.js` -> `InputSystem.res` (Keyboard shortcuts)
   - `AudioManager.js` -> `AudioManager.res` (Click sounds)
   - `DownloadSystem.js` -> `DownloadSystem.res` (Blob downloads)
   - `ProgressBar.js` -> `ProgressBar.res` (Progress UI)
   - `ModalManager.js` -> `ModalManager.res` (Generic modal logic)

2. **Migrate System Modules**:
   - `CacheSystem.js` -> `CacheSystem.res` (IndexedDB caching)
   - `VideoEncoder.js` -> `VideoEncoder.res` (Small utility for FFmpeg/WebM)
   - `UploadReport.js` -> `UploadReport.res` (The UI shown after uploads)

3. **Cleanup Adapter Files**:
   - Remove bridge files like `NavigationSystem.js` and `TeaserSystem.js` if they only wrap ReScript functions. Point JS callers directly to `.bs.js`.

## Testing Checklist
- [ ] Keyboard shortcuts (ESC to cancel) still work.
- [ ] Click sounds are played.
- [ ] Upload report shows up correctly with the summary of successful/skipped files.

## Definition of Done
- All listed JS files are deleted and replaced by ReScript native modules.
- Project is almost entirely ReScript (excluding entry points and constants).
