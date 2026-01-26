# Task 599: Implement Backend Integration Tests

## Description
The analysis report identified "placeholder" tests in several critical backend API modules. These need to be replaced with real integration tests that verify endpoint functionality.

## Requirements
1.  **Navigation**: Implement real tests for `backend/src/api/project/navigation.rs` verifying path calculation logic.
2.  **Geocoding**: Replace placeholders in `backend/src/api/geocoding.rs`.
3.  **Media**: Verify image processing endpoints in `backend/src/api/media/`.
4.  **Verification**: Ensure `cargo test` passes with increased coverage.

## Files
- `backend/src/api/project/navigation.rs`
- `backend/src/api/geocoding.rs`
- `backend/src/api/media/*.rs`

## Priority
Medium (Reliability)
