# Report 34: Logging Project Persistence

## Objective (Completed)
Migrate `ProjectManager.res` to use the new `Logger` module for structured logging of project save and load operations.

## Context
Project persistence (Save/Load) involves complex async flows including ZIP compression, backend uploading, validation, and file handling. Structured logging is essential for tracing failures in this critical path.

## Implementation Details

### 1. Save Operation (`saveProject`)
- **Start**: Logs `PROJECT_SAVE_START` with scene count and tour name.
- **Progress**: Logs `PACKAGE_CREATED` with the total blob size.
- **Complete**: Logs `PROJECT_SAVE_COMPLETE` with total duration.
- **Failure**: Logs `PROJECT_SAVE_FAILED` with error details.
- **Abort**: Logs `SAVE_ABORTED` if scene count is zero.

### 2. Load Operation (`loadProjectZip`)
- **Start**: Logs `PROJECT_LOAD_START` with filename and file size.
- **Validation**:
  - Logs `INVALID_FILE_TYPE` for non-blob assets.
  - Logs `IMAGE_MISSING_IN_ZIP` if assets are missing.
  - Logs `UNUSED_FILES_DETECTED` if the ZIP contains extra files.
  - Logs `SCENE_EXTRACTION_FAILED` for individual scene failures.
- **Complete**: Logs `PROJECT_LOAD_COMPLETE` with loaded scene count and duration.
- **Failure**: Logs `PROJECT_LOAD_FAILED` with error stack.

### 3. Changes
- Replaced `Console.warn` with `Logger.warn`.
- Replaced `Console.error` with `Logger.error`.
- Added manual timing (`Date.now()`) to track async durations across complex promise chains.

## Files Modified
- `src/systems/ProjectManager.res`

## Verification
- `npm run res:build` passed successfully.
