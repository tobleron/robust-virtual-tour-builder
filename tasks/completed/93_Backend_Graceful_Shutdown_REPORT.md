# Task 93: Add Backend Graceful Shutdown and Cleanup - REPORT

## Summary
Implemented graceful shutdown and cleanup procedures for the backend server.

## Changes
- **Shutdown Manager**: Created `backend/src/services/shutdown.rs` to manage active requests and coordinate cleanup.
- **Request Tracking**: Added `backend/src/middleware/request_tracker.rs` to track active requests.
- **Main Entry Point**: Updated `backend/src/main.rs` to:
    - Initialize `ShutdownManager`.
    - Handle SIGTERM/SIGINT signals.
    - Wait for active requests to complete with a configurable timeout.
    - Perform cleanup (persist caches, clean temp files) on exit.
    - Register tracking middleware.
- **Geocoding Service**: Updated `backend/src/services/geocoding.rs` to support configurable cache file paths and robust error handling during save.
- **API**: Added `backend/src/api/utils.rs` endpoint `trigger_shutdown` (admin only) for testing.
- **Project Structure**: Added `backend/src/lib.rs` to support integration testing.
- **Tests**: Added integration tests in `backend/tests/shutdown_test.rs` validating graceful shutdown and timeout behavior.

## Results
- `cargo test shutdown` passes successfully.
- Server now saves geocoding cache and cleans old temp files upon shutdown.
- Active requests are allowed to complete within the configured timeout period.
