---
description: Cleanup and consistency checks before pushing to GitHub.
---

# Pre-Push Workflow

Follow these steps before pushing major updates to the remote repository.

## 1. Cleanup Artifacts
// turbo
1. **Backend Cleanup**: If backend changes were made, run `cd backend && cargo clean && cd ..`.
2. **Log Cleanup**: Clear `logs/telemetry.log`.
3. **Test Data**: Remove temporary test files from `test/` folder (e.g., `.zip`, `.webp`).

## 2. Consistency Audit
1. **Version Sync**: Verify that `src/version.js`, `index.html`, `logs/log_changes.txt`, and the latest git commit message all use the EXACT SAME version number.
2. **Large Files**: Ensure no files over 1MB (especially binaries) are being pushed unless they are intended assets.

## 3. Git Status
1. **Ignored Files**: Confirm that `node_modules/` and `backend/target/` are correctly ignored by git.
