# Task: Remove Dead Image Analysis Code
**Priority:** High (Cleanup)
**Status:** Pending

## Objective
Remove the obsolete frontend implementation of image similarity analysis (`src/systems/ImageAnalysis.res`) and its associated wrappers, as this logic has been successfully migrated to the Rust backend (`BackendApi.batchCalculateSimilarity`) and is natively implemented in `backend/src/api/media.rs`.

## Context
Our analysis confirmed that:
1. `src/systems/ImageAnalysis.res` contains complex, CPU-intensive histogram intersection logic implemented in ReScript.
2. `src/systems/ExifParser.res` defines a wrapper `calculateSimilarity` that calls this local module.
3. However, the `UploadProcessor.res` (the primary user of this logic) **already calls `BackendApi.batchCalculateSimilarity`**.
4. Therefore, the local ReScript implementation is dead code that adds bloat and confusion.

## Requirements
1. **Delete** `src/systems/ImageAnalysis.res`.
2. **Remove** the `calculateSimilarity` wrapper function from `src/systems/ExifParser.res`.
3. **Verify** that no other files reference `ImageAnalysis`.
4. **Ensure** the project still compiles (`npm run res:build`).

## Verification
- Run `npm run res:build` to ensure no dangling references.
- Grep for `ImageAnalysis` to ensure total removal.
