---
description: Procedures for committing changes, including versioning and logging.
---

# Commit Workflow

Follow these steps when you are ready to commit your changes.

## 1. Preparation

### Code Quality
1. **Remove Raw Console Calls**: Delete all `console.log` statements in ReScript/JS code.
   - ❌ `Console.log(...)` or `console.log(...)`
   - ✅ Use `Logger.debug(...)` or `Debug.debug(...)` for persistent logging.
2. **Code Cleanup**: Remove commented-out code blocks unless they are specifically functional documentation.
3. **Verify Logging Standards**:
   - All new/modified ReScript modules should use `Logger` from `src/utils/Logger.res`.
   - Check for standardized log points: initialization, start/end of major operations, errors.

### Logging Audit
1. **Check for Debug Statements**: Ensure no `Logger.trace` or excessive `Logger.debug` calls are left in hot paths (animation loops, render cycles) unless intentional.
2. **Verify Error Handling**: Any `try/catch` or risky operations should use `Logger.attempt` or `Logger.attemptAsync` for automatic error logging.

## 2. Versioning & Documentation
1. **Increment Version**: 
   - Update `package.json`. Increment the patch version.
   - *Convention*: When Z reaches 9, increment Y and reset Z (e.g., `v4.9.9` → `v4.10.0`).
   - Run `node scripts/update-version.js` to sync the version to `src/utils/VersionData.res` and other files.
2. **Cache Busting**: 
   - Rsbuild handles content-based hashing automatically for assets.
   - For manual cache busting, `scripts/update-version.js` updates `index.html` with the version query string where applicable.
3. **Update Changelog**: 
   - Add a new entry to `CHANGELOG.md` under `[Unreleased]` or a new version header.
   - Follow the Keep a Changelog format: `### Added`, `### Changed`, `### Fixed`.
   - Format: `- Description of change.`

## 3. Verification
// turbo
1. **Build Check**: Run `npm run res:build` (for ReScript) and `npm run dev` to ensure everything compiles and works.
2. **Test Check**: Run `npm test` to ensure all unit tests pass before committing.
3. **Console Check**: Verify there are no errors in the browser console.
4. **Logger Check**: Temporarily enable debug mode (`DEBUG.enable()`) and verify logs appear correctly for modified modules.

## 4. Git Commit
1. **Stage Changes**: `git add .`
2. **Commit Message**: Use the format `vX.Y.Z [System/Feature] Description`.
   - Example: `git commit -m "v4.1.6 [Navigation] Fix coordinate wrap-around"`
3. **Verification Checklist**:
   - [ ] `package.json` updated
   - [ ] `src/utils/VersionData.res` updated (via `node scripts/update-version.js`)
   - [ ] `CHANGELOG.md` updated
   - [ ] No raw `console.log` statements
   - [ ] New modules use Logger system
