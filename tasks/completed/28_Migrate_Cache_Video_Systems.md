# Task 28: Migrate Cache and Video Systems to ReScript

## Status
- [ ] Pending

## Context
`CacheSystem.js` (IndexedDB) and `VideoEncoder.js` (Backend Wrapper) are legacy JavaScript files that need to be migrated to ReScript to ensure type safety and consistency with the new architecture.

## Objectives
1.  **Migrate `CacheSystem.js` to `CacheSystem.res`**
    - Implement IndexedDB bindings (or use a library/helper if available, otherwise write minimal bindings).
    - Ensure type safety for stored assets (blobs, metadata).
2.  **Migrate `VideoEncoder.js` to `VideoEncoder.res` or consolidate into `BackendApi.res`**
    - This module primarily calls the backend. It might fit well within `BackendApi.res` or a dedicated service module.
    - Ensure robust error handling and type-safe `FormData` usage.
3.  **Update Consumers**
    - Find all usages of `CacheSystem` and `VideoEncoder` and update them to use the new ReScript modules.

## Detailed Steps
1.  **Create `src/systems/CacheSystem.res`**
    - Bind to `indexedDB` global.
    - Re-implement `init`, `set`, `get`, `has`, `delete`, `clear`, `getStats`.
2.  **Create `src/systems/VideoEncoder.res`**
    - Implement `transcodeWebMToMP4` using `Fetch` and `FormData`.
    - Use `BackendApi` utilities if possible.
3.  **Refactor `UploadProcessor.res` / `TeaserRecorder.res`**
    - These likely use `VideoEncoder` or `CacheSystem`. Update them to use the new modules.
4.  **Delete Legacy Files**
    - Remove `src/systems/CacheSystem.js`.
    - Remove `src/systems/VideoEncoder.js`.

## Verification
- Run the build: `npm run res:build`.
- Verify no compilation errors.
- Test "Save Project" (if it uses cache) or "Generate Teaser" (uses VideoEncoder) to ensure functionality works.
