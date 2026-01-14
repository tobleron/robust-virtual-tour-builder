# Task: Backend Safety Audit (Unwrap Elimination)
**Priority:** High (Stability)
**Status:** Pending

## Objective
Audit the entire Rust backend codebase to ensure **zero panics** in production code paths.

## Context
A quick scan revealed potential `unwrap()` usage. While some are in tests (which is fine), any `unwrap()` in a request handler or service logic is a potential Denial of Service vector (crashing the server).

## Requirements
1. **Audit** `backend/src/**/*.rs`.
2. **Replace** unsafe `unwrap()` calls with proper error handling:
   - `Option::unwrap()` -> `ok_or(AppError::...)` or `unwrap_or(...)`.
   - `Result::unwrap()` -> `map_err(...)` + `?`.
3. **Focus Areas**:
   - `backend/src/services/`
   - `backend/src/api/`
   - `backend/src/pathfinder.rs`
4. **Exemption**: Tests (`#[cfg(test)]`) and `main.rs` *startup* configuration (where panic on invalid config is acceptable).

## Verification
- Grep for `unwrap()` in `backend/src`.
- Ensure remaining instances are only in tests or startup logic.
- Run `cargo test` to ensure no regressions.
