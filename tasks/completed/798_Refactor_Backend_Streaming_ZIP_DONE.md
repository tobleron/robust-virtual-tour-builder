# Task: 798 - Refactor: Streaming ZIP Orchestration (High-Large Scale Compatibility)

## Objective
Refactor the backend project processing logic to use streaming and disk-backed storage instead of in-memory buffers to support multi-gigabyte virtual tour uploads.

## Technical Context
Current implementation in `backend/src/services/project/load.rs` (specifically `process_uploaded_project_zip`) reads the entire uploaded ZIP into a `Vec<u8>`. For commercial tours, this can easily exceed available RAM, leading to server crashes (OOM).

## Implementation Plan
1. **Dependency Analysis**: Ensure `tempfile` crate is available in `backend/Cargo.toml`.
2. **Streaming Ingestion**: Modify `process_uploaded_project_zip` to accept a `std::fs::File` or similar reader instead of `Vec<u8>`.
3. **Chunked Processing**:
   - Use `tempfile` to create a working scratch space.
   - Iterate through ZIP entries using `ZipArchive` without inflating all files into memory.
4. **Streaming Output**: Use a buffered `ZipWriter` to write the normalized ZIP directly to a temporary file on disk.
5. **Memory Limit Guard**: Add a configurable memory limit check for the remaining metadata operations.

## Verification Criteria
- [ ] Pass `cargo test` in backend.
- [ ] Successfully process a large tour ZIP (simulate via unit test if possible).
- [ ] `npm run build` passes.
- [ ] Zero compiler warnings.

## Related Modules
- `backend/src/services/project/load.rs`
- `backend/src/api/project/storage/storage_logic.rs`
