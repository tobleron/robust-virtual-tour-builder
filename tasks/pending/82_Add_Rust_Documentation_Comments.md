# Task 82: Add Rust Documentation Comments

## Priority: 🟢 LOW

## Context
Many public functions in the Rust backend lack `///` documentation comments. This makes onboarding new developers harder and reduces IDE assistance.

## Standards
Use Rust's standard documentation format:
```rust
/// Brief one-line description.
///
/// More detailed explanation if needed.
/// Can span multiple paragraphs.
///
/// # Arguments
/// * `param1` - Description of parameter
/// * `param2` - Description of parameter
///
/// # Returns
/// Description of return value
///
/// # Errors
/// Description of error conditions
///
/// # Example
/// ```
/// let result = function_name(arg1, arg2);
/// ```
pub fn function_name(param1: Type1, param2: Type2) -> Result<ReturnType, Error>
```

## Functions to Document

### High Priority (Public API Handlers)

1. **api/project.rs**
   - [ ] `create_tour_package` - What it creates, format, prerequisites
   - [ ] `save_project` - Project format, what's included
   - [ ] `load_project` - Expected ZIP structure
   - [ ] `validate_project` - What validations are performed
   - [ ] `import_project` - Difference from load, session handling
   - [ ] `calculate_path` - Algorithm explanation, parameters

2. **api/media/image.rs**
   - [ ] `process_image_full` - Pipeline steps, output format
   - [ ] `optimize_image` - Parameters, quality tradeoffs
   - [ ] `resize_image_batch` - Parallel processing details
   - [ ] `extract_metadata` - EXIF fields extracted

3. **api/geocoding.rs**
   - [ ] `reverse_geocode` - API used, caching behavior

### Medium Priority (Services)

4. **services/project.rs**
   - [ ] `validate_zip_project` - Validation rules
   - [ ] `load_zip_to_session` - Session lifecycle

5. **services/media.rs**
   - [ ] `calculate_quality_analysis` - Scoring algorithm
   - [ ] `extract_exif` - Fields handled

6. **services/geocoding.rs**
   - [ ] `get_cached_or_fetch` - Cache strategy
   - [ ] `load_cache_from_disk` - File format

### Low Priority (Helpers)

7. **pathfinder.rs**
   - [ ] `calculate_walk_path` - Algorithm
   - [ ] `calculate_timeline_path` - Timeline handling
   - [ ] `follow_auto_forward_chain` - Chain behavior

## Example Documentation

```rust
/// Processes an uploaded panorama image through the full optimization pipeline.
///
/// The pipeline performs the following steps:
/// 1. Decode the source image (JPEG, PNG, WebP, HEIC)
/// 2. Extract EXIF metadata (camera info, GPS, timestamp)
/// 3. Analyze image quality (luminance, sharpness, clipping)
/// 4. Generate multi-resolution outputs:
///    - `preview.webp` (2048px width, quality 80)
///    - `tiny.webp` (256px width, quality 60)
/// 5. Compute SHA-256 checksum for duplicate detection
///
/// # Arguments
/// * `payload` - Multipart form data containing a single image file
///
/// # Returns
/// A ZIP file containing:
/// - `preview.webp` - Optimized preview image
/// - `tiny.webp` - Thumbnail for sidebar
/// - `metadata.json` - EXIF data, quality analysis, checksum
///
/// # Errors
/// - `BadRequest` if no file provided or file is not an image
/// - `ProcessingError` if image decoding fails
/// - `InternalError` for unexpected failures
pub async fn process_image_full(mut payload: Multipart) -> Result<HttpResponse, AppError> {
```

## Acceptance Criteria
- [ ] All public API handlers have `///` comments
- [ ] All public service functions have `///` comments
- [ ] `cargo doc --open` generates readable documentation
- [ ] No `missing_docs` warnings (if lint enabled)

## Files to Modify
- `backend/src/api/project.rs`
- `backend/src/api/media/image.rs`
- `backend/src/api/media/video.rs`
- `backend/src/api/media/similarity.rs`
- `backend/src/api/geocoding.rs`
- `backend/src/services/*.rs`
- `backend/src/pathfinder.rs`

## Testing
```bash
cd backend
cargo doc --no-deps --open  # Generate and view docs
```
