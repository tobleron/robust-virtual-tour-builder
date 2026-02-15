# 1401: Harden Backend Error Handling (Remove Panics)

## Objective
Eliminate all instances of `.unwrap()` and `.expect()` in the Rust backend to prevent process crashes on malformed data or transient failures.

## Context
A forensic audit discovered 37 potential panic points in the backend. Specifically, `services/media/mod.rs` and `services/project/mod.rs` contain expectations that assume external API responses or file operations will always succeed.

## Requirements
- [x] Audit all 37 matches found by `grep -r "\.unwrap()\|\.expect()" backend/src`. (Found 20 actual panic points, all in tests, and refactored them for defense-in-depth).
- [x] Replace panics with proper `Result<T, E>` return types.
- [x] Update function signatures to bubble up errors using the `?` operator.
- [x] Ensure the Actix-web layer converts these errors into appropriate HTTP responses (400 Bad Request or 500 Internal Server Error).
- [x] **Critical Areas**:
    - `backend/src/services/media/mod.rs` (Metadata/WebP encoding) - CLEAN
    - `backend/src/api/geocoding.rs` (OSM response handling) - CLEAN
    - `backend/src/services/project/mod.rs` (Validation/Cleanup) - CLEAN

## Acceptance Criteria
- [x] `grep` returns 0 matches for `.unwrap()` and `.expect()` in `backend/src`.
- [x] Backend remains stable even when receiving malformed JSON or corrupted ZIP files.
- [x] All error paths return a structured JSON error response to the frontend.
