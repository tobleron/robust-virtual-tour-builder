---
description: Cleanup and consistency checks before pushing to GitHub.
---

# Pre-Push Workflow

Follow these steps before pushing major updates to the remote repository.

## 1. Quality Verification
// turbo
1. **Full Test Suite**: Run `npm test` to ensure both frontend and backend tests pass.
2. **Backend Verification**: If backend changes were made, run `cd backend && cargo test && cd ..` for deep verification.
3. **Log File Cleanup**: 
   - Clear `logs/telemetry.log` (development logs shouldn't be pushed).
   - Clear `logs/error.log` if it contains only test errors.
   - Keep `logs/log_changes.txt` (this is the changelog).
4. **Test Data**: Remove temporary test files from `test/` folder (e.g., `.zip`, `.webp`).

## 2. Consistency Audit
1. **Version Sync**: Verify that `src/version.js`, `index.html`, `logs/log_changes.txt`, and the latest git commit message all use the EXACT SAME version number.
2. **Large Files**: Ensure no files over 1MB (especially binaries) are being pushed unless they are intended assets.

## 3. Logging System Check
1. **Debug Level**: Ensure `DEBUG_LOG_LEVEL` in `src/constants.js` is set to `'info'` (not `'debug'` or `'trace'`).
2. **Debug Default**: Ensure `DEBUG_ENABLED_DEFAULT` in `src/constants.js` is `false` for production.
3. **No Test Logs**: Verify log files don't contain test entries like `TEST_LOG_ENTRY` or `TEST_ERROR_ENTRY`.

## 4. Git Status
1. **Ignored Files**: Confirm that `node_modules/` and `backend/target/` are correctly ignored by git.
2. **Log Files**: Confirm `logs/*.log` files are not staged (should be in `.gitignore`).

## 5. Final Verification
// turbo
1. **Clean Build**: Run `npm run res:build` to ensure no compilation errors.
2. **Production Ready**: Verify the app works correctly with debug mode disabled.
