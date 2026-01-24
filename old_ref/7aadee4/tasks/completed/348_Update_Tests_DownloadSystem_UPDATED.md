# Task 348: Update Unit Tests for DownloadSystem.res - REPORT

## Objective
Update `tests/unit/DownloadSystemTest.res` to ensure it covers recent changes in `DownloadSystem.res` and migrate to Vitest.

## Realization
- **Migration**: Migrated all unit tests for `DownloadSystem` to Vitest.
- **New Test File**: Created `tests/unit/DownloadSystem_v.test.res`.
- **Coverage & Bug Fix**:
    - **Bug Discovery**: During migration, a bug was found in `DownloadSystem.res` where arguments to `String.includes` were swapped, causing `AbortError` detection (user cancellation) to fail.
    - **Bug Fix**: Swapped the arguments in `DownloadSystem.res` line 128 to correctly check `String.includes(msg, "AbortError")`.
    - **New Logic Coverage**: Added tests for `saveBlobWithConfirmation` covering both the File System Access API (native path) and the legacy fallback path.
    - **Error Handling**: Verified that `USER_CANCELLED` is correctly returned when the user cancels the file picker.
    - **Sanity Checks**: Verified `getExtension` with various edge cases (multiple dots, no dots, trailing dots).
- **Cleanup**: 
    - Updated `tests/TestRunner.res` to remove legacy task execution.
    - Deleted deprecated `tests/unit/DownloadSystemTest.res`.
- **Verification**: Ran `npm run test:frontend` confirming all 273 tests pass, including the fixed `AbortError` logic.

## Technical Details
- Mocked `window.showSaveFilePicker` and `URL.createObjectURL` to simulate browser environments in Vitest.
- Used `afterEach` to restore global state and prevent test pollution.
- Verified that `downloadZip` handles `null` references safely without crashing.
