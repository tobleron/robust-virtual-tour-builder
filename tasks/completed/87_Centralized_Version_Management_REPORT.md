# Task 87 Report: Centralized Version Management

## Status: ✅ COMPLETED
**Date:** 2026-01-14
**Version:** 4.2.57

## Changes Implemented

### 1. Centralized Version Source
- The `package.json` file is now the single source of truth for the application version.
- Added a `version-sync` script to `package.json`.
- Added a `postversion` hook to `package.json` to automatically sync versions after running `npm version`.

### 2. Version Synchronization Script
- Created `scripts/update-version.js` which:
    - Reads the current version from `package.json`.
    - Updates all cache busters (`?v=...`) in `index.html`.
    - Corrects the malformed Content-Security-Policy header in `index.html`.
    - Updates `src/version.js` with the current version and build info.

### 3. ReScript Version Utility
- Created `src/utils/Version.res` to provide a type-safe way to access the version in the frontend code.
- Functions provided:
    - `getVersion()`: Returns the version string (e.g., "4.2.57").
    - `getBuildInfo()`: Returns build info (e.g., "[Stable Release]").
    - `getFullVersion()`: Returns a combined string.

### 4. Cleanup
- Fixed the malformed CSP header in `index.html` which was accidentally containing version numbers in the `http-equiv` attribute.

## Verification Results
- Ran `npm run version-sync` manually: Successfully updated `index.html` and `src/version.js`.
- Verified `index.html` content: Cache busters and CSP header are correct.
- Verified build: `npm run res:build` succeeds with the new `Version.res` module.
- Verified automation: The commit script successfully triggered the version bump and sync.

## How to Bump Version in the Future
To update the version, simply run:
```bash
npm version <patch|minor|major>
```
The `postversion` hook will automatically update `index.html` and `src/version.js`, and these changes will be included in the version commit.
