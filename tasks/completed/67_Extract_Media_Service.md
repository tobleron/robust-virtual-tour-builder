# Task 67: Backend Service Extraction: Media and Image Processing

**Status:** Completed  
**Priority:** HIGH  
**Category:** Backend Refactoring  
**Estimated Effort:** 2-3 hours

---

## Objective

Extract low-level image and video processing logic from HTTP handlers into a dedicated `MediaService`. This separates "how to process" from "how to handle requests."

---

## Context

**Current State:**
Functions like `encode_webp`, `resize_fast`, and `perform_metadata_extraction` are helper functions in `handlers.rs`. They contain complex logic using the `image` crate and custom bit-manipulation for WebP chunks.

**Why This Matters:**
- **Reusability:** Other parts of the backend might eventually need to process images without going through an HTTP route.
- **Testing:** Pure logic can be tested without mocking Actix-web's `Multipart` or `web::Json`.
- **Clarity:** Reduces the cognitive load of `handlers.rs`.

---

## Requirements

### Technical Requirements
1. Create `backend/src/services/media.rs`.
2. Move logic that doesn't depend on Actix-web types (like `Multipart`) into this service.
3. Keep handlers in `handlers.rs` for now, but have them delegate to `MediaService`.

---

## Implementation Steps

### Step 1: Create Media Service
- Create `backend/src/services/mod.rs` and `backend/src/services/media.rs`.
- Add `mod services;` to `main.rs`.

### Step 2: Extract Image Logic
Move the following functions from `handlers.rs` to `services/media.rs`:
- `encode_webp`
- `resize_fast_rgba`
- `resize_fast`
- `perform_metadata_extraction_rgba`
- `perform_metadata_extraction`
- `inject_remx_chunk`

### Step 3: Refactor Handlers
Update handlers in `handlers.rs` to call the new service:
- `optimize_image`
- `process_image_full`
- `resize_image_batch`
- `extract_metadata`

Example transformation:
```rust
// Before: handler does the work
pub async fn optimize_image(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    // ... logic to get pixels ...
    let webp_data = encode_webp(&img, quality)?; // helper in same file
    // ...
}

// After: handler delegates
pub async fn optimize_image(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    // ... logic to get pixels ...
    let webp_data = services::media::encode_webp(&img, quality)?;
    // ...
}
```

---

## Testing Criteria

### Correctness
- [ ] Backend compiles successfully.
- [ ] Manual test: Upload an image via the frontend and verify it is processed correctly (quality check, metadata extraction).
- [ ] Verify WebP injection (REMX chunk) is still present using `exiftool` or a hex editor on output files.

---

## Rollback Plan
- Git revert the commit and restore helper functions to `handlers.rs`.

---

## Related Files
- `backend/src/handlers.rs`
- `backend/src/services/media.rs` (New)
- `backend/src/main.rs`
