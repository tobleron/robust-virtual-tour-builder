# Task: Wire Backend Similarity Calculation
**Priority:** Medium (Performance)
**Status:** Pending

## Objective
Ensure that all parts of the application that require image similarity checks use the high-performance Rust backend endpoint (`/api/media/similarity`) instead of any remaining frontend logic.

## Context
While `UploadProcessor.res` correctly uses the backend, we need to guarantee that `ExifParser.res` or any other utility functions do not fall back to slow, main-thread blocking JS/ReScript implementations.

## Requirements
1. **Audit** `src/systems/ExifParser.res`. If it needs to expose similarity logic, it **must** use `BackendApi.batchCalculateSimilarity`.
2. **Refactor** any single-comparison calls to use the batch API (even for 1 pair) to leverage Rust's speed and SIMD optimizations.
3. **Delete** any residual "histogram intersection" math from the frontend codebase.

## Verification
- Check `ExifParser.res` source code.
- Verify `BackendApi.res` is the *only* place where `/similarity` endpoint is called.
