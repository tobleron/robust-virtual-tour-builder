# Task 1279: Backend Quality & Dead Code Cleanup

## Objective
Eliminate all Rust compiler warnings to adhere to "Zero Warnings" enterprise quality standards.

## Context
Running `cargo test` produced 11 warnings related to unused imports and dead code. While the tests passed, these warnings indicate accumulating technical debt and clutter.

**Warnings Identified:**
1.  `unused import: super::*` in `src/api/media/image.rs`
2.  `unused import: crate::models::CachedGeocode` in `src/services/geocoding/mod.rs`
3.  Unused function: `rotate_log_file` in `src/api/telemetry.rs`
4.  Unused function: `append_to_log` in `src/api/telemetry.rs`
5.  Unused constant: `MAX_LOG_SIZE` in `src/api/utils.rs`
6.  Unused constant: `MAX_LOG_FILES` in `src/api/utils.rs`
7.  Unused function: `encode_token` in `src/auth.rs`

## Requirements
1.  **Clean Up**: Remove or prefix with `_` (if intended for future use) the unused code.
    - If `encode_token` is needed for future auth flow, keep it but allow dead code or use `#[allow(dead_code)]` with a TODO. Ideally, remove if not planned for immediate use.
    - Remove unused imports.
2.  **Verify**: Run `cargo test` and ensure output is clean (no warnings).
3.  **Safety**: Ensure no side effects on compilation or running logic.

## Step-by-Step
1.  Edit `backend/src/api/media/image.rs`: Remove `use super::*;`
2.  Edit `backend/src/services/geocoding/mod.rs`: Remove `use crate::models::CachedGeocode;`
3.  Edit `backend/src/api/telemetry.rs`: Remove/Comment `rotate_log_file` and `append_to_log`.
4.  Edit `backend/src/api/utils.rs`: Remove `MAX_LOG_SIZE` and `MAX_LOG_FILES`.
5.  Edit `backend/src/auth.rs`: Check `encode_token` usage. If strictly unused by app, remove or `#[allow(dead_code)]`.

## Acceptance Criteria
- [ ] `cargo check` returns 0 warnings.
- [ ] `cargo test` passes 100%.
