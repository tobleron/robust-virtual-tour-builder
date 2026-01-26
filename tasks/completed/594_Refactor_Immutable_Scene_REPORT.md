# Refactor Immutable Scene Record - REPORT

## Objective
The goal was to enforce immutability in the core domain models by removing the `mutable preCalculatedSnapshot` field from the `scene` record in `src/core/Types.res`. This field was used for ephemeral visual state (storing blob URLs of snapshots for smooth transitions) and violated the principle of immutable domain records.

## Technical Realization
1.  **Created `src/core/SceneCache.res`**: A new side-effect isolated module was introduced to manage scene snapshots. It uses a `Belt.MutableMap.String.t` to store `sceneId -> blobUrl` mappings.
2.  **Refactored `Types.res`**: Removed the `mutable preCalculatedSnapshot` field from the `scene` record. 
3.  **Updated Snapshot Logic**:
    *   `src/components/ViewerSnapshot.res` now uses `SceneCache.setSnapshot` to store newly captured snapshots.
    *   `src/systems/SceneLoader.res` and `src/systems/SceneTransitionManager.res` now use `SceneCache.getSnapshot` to retrieve snapshots during transitions.
    *   `src/systems/TeaserPlayback.res` and `src/systems/TeaserRecorder.res` were updated to use the new cache.
4.  **Test Verification**:
    *   Updated multiple unit tests (including `ViewerSnapshot_v.test.res`, `Types_v.test.res`, etc.) to align with the new immutable structure.
    *   Verified that snapshots are correctly captured, retrieved, and automatically revoked via the cache to prevent memory leaks.

## Verification
-   Ran `npx vitest tests/unit/ViewerSnapshot_v.test.bs.js` - **PASSED**.
-   Full build verification via `commit.sh` confirmed NO warnings and NO broken references.
