# Report: Migrate Remaining Modules to Logger System

## Objective (Completed)
Update all remaining ReScript modules that use logging to use the new Logger system for consistency.

## Context
This is a catch-all task to ensure complete logging coverage across the codebase. After the major modules have been migrated, this task covers smaller utility modules.

## Prerequisites
- Previous logging migration tasks completed

## Modules to Migrate

### Systems

| Module | Priority | Notes |
|--------|----------|-------|
| `AudioManager.res` | Low | Audio playback logging |
| `BackendApi.res` | Medium | API call logging |
| `DownloadSystem.res` | Medium | Download trigger logging |
| `ExifParser.res` | Medium | EXIF parsing logging |
| `ProjectManager.res` | Medium | Project operations logging |
| `Resizer.res` | Medium | Client-side resize logging |
| `ServerTeaser.res` | Low | Server teaser operations |

### Components

| Module | Priority | Notes |
|--------|----------|-------|
| `ViewerSnapshot.res` | Low | Snapshot capture logging |
| `SceneList.res` | Low | UI interactions |
| `LabelMenu.res` | Low | Menu interactions |

### Utils

| Module | Priority | Notes |
|--------|----------|-------|
| `ProgressBar.res` | Low | Progress updates (trace level) |
| `TourLogic.res` | Low | Tour calculations |

## Implementation Pattern

For each module, follow this pattern:

1. **Find existing Debug calls**:
   ```bash
   grep -n "Debug\." src/systems/ModuleName.res
   ```

2. **Replace with Logger calls**:
   - `Console.log` → `Logger.debug`
   - `Console.error` → `Logger.error`
   - `Debug.info` → `Logger.info`
   - `ReBindings.Debug.warn` → `Logger.warn`

3. **Add initialization log** (if applicable):
   ```rescript
   Logger.initialized(~module_="ModuleName")
   ```

4. **Verify compilation**:
   ```bash
   npm run res:build
   ```

## Standard Migration Checklist Per Module

- [ ] Replace Console.* calls with Logger calls
- [ ] Replace Debug.* calls with Logger calls
- [ ] Replace ReBindings.Debug.* calls with Logger calls
- [ ] Add appropriate log levels
- [ ] Add data context where useful
- [ ] Verify compilation

## Files to Modify

All `.res` files in `src/systems/` and `src/components/` that haven't been covered by previous tasks.

## Testing Checklist

- [ ] All modules compile without errors
- [ ] DEBUG.getSummary() shows all module names
- [ ] No remaining Console.log calls in ReScript files
- [ ] No remaining old-style Debug calls

## Definition of Done

- All ReScript modules use Logger consistently
- No mixing of Debug and Logger calls
- Complete logging coverage across codebase
