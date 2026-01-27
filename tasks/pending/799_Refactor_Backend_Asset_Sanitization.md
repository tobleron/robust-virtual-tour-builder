# Task: 799 - Refactor: Hardened Asset Sanitization Utility (Security)

## Objective
Implement a robust security layer for asset path normalization to prevent "Zip Slip" vulnerabilities and ensure consistent asset mapping.

## Technical Context
The project processing logic extracts files from user-uploaded ZIPs. While rudimentary checks exist, a hardened sanitization layer is needed to ensure that no malicious path segments (e.g., `../../`) are preserved and that the internal structure of the tour is strictly enforced.

## Implementation Plan
1. **Normalization Logic**: Create a new utility function in `backend/src/services/project/validate.rs` or a dedicated `naming.rs`.
2. **Path Sanitization**:
   - Aggressively strip relative path segments (`../`, `./`).
   - Remove any absolute path prefixes.
   - Force all image assets into the `images/` directory within the virtual archive.
3. **Conflict Resolution**: Implement a deterministic mapping for duplicate filenames (e.g., appending a hash or sequential ID).
4. **Integration**: Inject this normalization layer into the `load.rs` repackaging loop.
5. **Security Verification**: Add unit tests in `backend` specifically testing for malicious path traversal attempts in ZIP entries.

## Verification Criteria
- [ ] Malicious ZIP entries with `..` paths are successfully sanitized to safe paths.
- [ ] All assets are correctly mapped to the `images/` folder in the final ZIP.
- [ ] `cargo test` passes.
- [ ] `npm run build` passes.

## Related Modules
- `backend/src/services/project/load.rs`
- `backend/src/services/project/validate.rs`
- `backend/src/services/media/naming.rs`
