# Report 29: Refactor Teaser Logic and Server Generation

## Status
- [ ] Pending

## Context
`TeaserSystem.js` currently contains mixed logic: bridging to `TeaserManager.res` for client-side recording, AND implementing `generateServerTeaser` for server-side generation using `fetch`. This logic should be unified in ReScript.

## Objectives
1.  **Migrate Server Generation Logic**
    - Move `generateServerTeaser` logic to `BackendApi.res` (or a specific `ServerTeaser.res` module).
    - Ensure strictly typed `projectData` construction matching the backend expectations.
2.  **Deprecate `TeaserSystem.js`**
    - The file acts mainly as a bridge now. Once server logic is moved, it can be removed.
    - Update consumers (UI buttons, context menus) to call `TeaserManager.res` or `BackendApi.res` directly.
3.  **Update `TeaserManager.res`**
    - Ensure it can handle the "Cinematic + MP4" flow which triggers the server generation, or delegate it to the new server module.

## Detailed Steps
1.  **Enhance `BackendApi.res`**
    - Add `generateTeaser` function that accepts project data and files, implementing the `fetch` call to `/generate-teaser`.
2.  **Update consumers in `Sidebar.res` or `Components`**
    - Instead of calling `TeaserSystem.startAutoTeaser`, call `TeaserManager` or `BackendApi` directly.
3.  **Handle Progress Updates**
    - Ensure the progress callbacks (`onProgress`) are correctly typed and passed from ReScript to the UI (ProgressBar).
4.  **Delete `src/systems/TeaserSystem.js`**

## Verification
- Run `npm run res:build`.
- Verify Teaser generation (both implementations if possible) behaves as expected.
