# Task 66: Extract Backend Domain Types and Error System

**Status:** Pending  
**Priority:** HIGH  
**Category:** Backend Refactoring  
**Estimated Effort:** 1-2 hours

---

## Objective

Create a dedicated domain layer for the Rust backend by extracting shared types, models, and error handling from the monolithic `handlers.rs` into focused modules.

---

## Context

**Current State:**
All backend domain logic and HTTP handlers are co-located in `backend/src/handlers.rs` (2700+ lines). This includes:
1. `AppError` and its conversion traits.
2. DTOs for image metadata, GPS, and geocoding.
3. Validation reports and telemetry structs.

**Why This Matters:**
- **Circular Dependencies:** Hard to add new modules if they all need to import from `handlers.rs`.
- **Maintainability:** Finding a specific type requires searching a 100kb file.
- **Scaling:** Necessary foundation for breaking handlers into smaller, focused files.

---

## Requirements

### Technical Requirements
1. Create `backend/src/models/mod.rs` (or `backend/src/domain/types.rs`).
2. Move all `struct` and `enum` definitions that are shared between handlers and services.
3. Move `AppError` and its `From` / `ResponseError` implementations.
4. Ensure `Cargo.toml` has necessary dependencies for the new modules (e.g. `serde`, `actix-web`).
5. Update `main.rs` and `handlers.rs` imports.

---

## Implementation Steps

### Step 1: Create Directory Structure
- Create `backend/src/models/`
- Add `mod.rs` to expose the models.

### Step 2: Extract Error Handling
Move the following from `handlers.rs` (approx. lines 40-110) to `models/errors.rs`:
- `ErrorResponse`
- `AppError`
- All `impl From<...> for AppError`
- `impl ResponseError for AppError`

### Step 3: Extract Domain DTOs
Move the following to `models/mod.rs`:
- `GpsData`
- `ExifMetadata`
- `QualityStats`
- `ColorHist`
- `QualityAnalysis`
- `MetadataResponse`
- `GeocodeRequest` / `GeocodeResponse`
- `CachedGeocode`
- `SimilarityPair` / `SimilarityRequest` / `SimilarityResponse` / `SimilarityResult`
- `ValidationReport`
- `TelemetryEntry`

### Step 4: Update Module Tree
Update `backend/src/main.rs`:
```rust
mod models;
mod handlers;
mod pathfinder;
```

### Step 5: Fix Imports
Update `handlers.rs` and `pathfinder.rs` to use the new models:
```rust
use crate::models::{AppError, MetadataResponse, ...};
```

---

## Testing Criteria

### Correctness
- [ ] Backend compiles successfully with `cargo build`.
- [ ] All unit tests in `handlers.rs` still pass.
- [ ] `main.rs` route registration remains unchanged.

### Verification
- [ ] Verify `handlers.rs` size is reduced by ~600 lines.
- [ ] Verify no circular imports between `models` and `handlers`.

---

## Rollback Plan
- Git revert the commit and restore the monolithic `handlers.rs`.

---

## Related Files
- `backend/src/handlers.rs`
- `backend/src/main.rs`
- `backend/src/models/mod.rs` (New)
