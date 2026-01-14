# Task: Backend Filename & Checksum Enhancements

## Objective
Offload filename suggestion logic and checksum generation to the Rust backend to simplify the frontend and improve performance.

## Context
Rust is significantly faster at SHA-256 than JavaScript. Moving naming logic to the backend also ensures consistency across different upload sources.

## Implementation Steps

1. **Add `suggested_name` to `MetadataResponse`**:
   - In `backend/src/handlers.rs`, update `MetadataResponse` struct.
   - Implement `get_suggested_name` helper (strip extensions, apply Regex pattern `_(\d{6})_\d{2}_(\d{3})`).

2. **Verify Checksum implementation**:
   - Ensure the backend calculates SHA-256 for every processed image.
   - Format: `{hex_hash}_{file_size}`.
   - Include this in the `metadata.json` returned in the `process-image-full` ZIP.

3. **In-place Re-optimization Prevention**:
   - When processing an image, check for existing `reMX` chunks (custom WebP chunk).
   - If found, read previous metadata and return it instead of re-analyzing, preserving the original checksum if valid.

## Testing Checklist
- [x] Process image `_240113_01_001.jpg`. Verify `suggested_name` is `240113_001`.
- [x] Check `metadata.json` for a valid `checksum` field.
- [x] Measure throughput of batch processing with 10 images.

## Definition of Done
- `suggested_name` returned for all uploads.
- `checksum` included in all metadata responses.
- Backend handles re-upload efficiently using reMX chunks.
